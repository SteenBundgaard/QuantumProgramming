namespace Quantum.Shor {
    import Std.Arithmetic.ApplyIfGreaterOrEqualL;
    import Std.Math.TimesCP;
    import Std.Math.AbsI;
    import Std.Math.BitSizeI;
    import Std.Math.Max;
    import Std.Diagnostics.DumpRegister;
    import Std.ResourceEstimation.RepeatEstimates;
    import Std.Diagnostics.DumpMachine;
    import Microsoft.Quantum.Diagnostics.*;
    import Microsoft.Quantum.Math.*;
    import Microsoft.Quantum.Arrays.*;
    import Microsoft.Quantum.Convert.*;
    import Quantum.Shared.*;

   // @EntryPoint()
    operation RunModularExponentiation() : Unit {
        let N = 7;
        let aInitial = 3;
        let nBits = BitSizeI(N);
        let registerLength = nBits + 1; // an extra bit is required for the arithemetic operations
        use (x, result) = (Qubit[registerLength * 2], Qubit[registerLength]); // for RSA the number of bits are registerLength= 4096
        // prepare with all possible values of x
        ApplyToEach(H, x);        
        // Calculates a^X mod N
        QuantumExponentiationModuloN(N, aInitial, result, x);
        // measure
        let modularExponentiationResult = MeasureInt(result);
        let xMeasure = MeasureInt(x);
        Message($"Final Result: x = {xMeasure} ; modularExponentiationResult = {modularExponentiationResult}");
        // release       
        ResetAll(result);  
        ResetAll(x);
    }

    operation QuantumExponentiationModuloN(N : Int, aInitial : Int, result : Qubit[], x : Qubit[]) : Unit {      
        let nBits = BitSizeI(N);
        let registerLength = nBits + 1;
        mutable a = aInitial;
        use divisor = Qubit[registerLength];  // all qubit registers in the operation are 'ancillas' but used differently
        use baseValue = Qubit[registerLength];
        use tempResult = Qubit[2 * registerLength];
        use ancilla = Qubit[registerLength];
        use ancilla2 = Qubit[registerLength];
        use ancilla3 = Qubit[registerLength];
        use ancilla4 = Qubit[registerLength];

        InitializeQubitsFromInteger(1, result);

        for v in 0..Length(x) - 1 {
            Controlled QuantumMultiplierModuloN([x[v]], (a, N, registerLength, baseValue, divisor, result, tempResult, ancilla, ancilla2, ancilla3, ancilla4));
            // swap result and tempResult
            let lastIndex = ((2 <<< (registerLength - 1)) - 1 + ((1 <<< (registerLength - 1)) - 1)) % 2 * registerLength;
            for i in 0..registerLength - 1 {
                CCNOT(x[v], tempResult[lastIndex + i], result[i]);
                CCNOT(x[v], result[i], tempResult[lastIndex + i]);
                CCNOT(x[v], tempResult[lastIndex + i], result[i]);
            }
            // uncompute tempresult
            let modInverse = ModInverse(a, N);
            Controlled Adjoint QuantumMultiplierModuloN([x[v]], (modInverse, N, registerLength, baseValue, divisor, result, tempResult, ancilla, ancilla2, ancilla3, ancilla4));
            a = (a * a) % N;
        }
    }

    function ModInverse(a : Int, n : Int) : Int {
        mutable t = 0;
        mutable newt = 1;
        mutable r = n;
        mutable newr = a;

        while newr != 0 {
            let quotient = r / newr;

            let tempt = t;
            t = newt;
            newt = tempt - quotient * newt;

            let tempr = r;
            r = newr;
            newr = tempr - quotient * newr;
        }

        if r > 1 {
            fail "Modulær invers eksisterer ikke";
        }

        if t < 0 {
            t += n;
        }

        return t;
    }

    operation QuantumMultiplierModuloN(a : Int, N : Int, registerLength : Int, baseValue : Qubit[], divisor : Qubit[], result : Qubit[], tempResult : Qubit[], ancilla : Qubit[], ancilla2 : Qubit[], ancilla3 : Qubit[], ancilla4 : Qubit[]) : Unit is Adj + Ctl {
        for i in 0..registerLength - 1 {
            within {
                for j in 0..Length(baseValue) - 1 {
                    if ((a &&& (1 <<< j)) != 0) {
                        CNOT(result[i], baseValue[j]);
                    }
                    if ((N &&& (1 <<< j)) != 0) {
                        CNOT(result[i], divisor[j]);
                    }
                }
            } apply {
                for k in 0..(1 <<< i) - 1 {
                    let tempIndex = i > 0 ? ((2 <<< i) - 1 + k) % 2 * registerLength | 0;
                    let prevTempIndex = i > 0 ? ((2 <<< i) + k) % 2 * registerLength | registerLength;                    
                    within {
                        // t1 = a0 + baseValue
                        QuantumAdder(baseValue, tempResult[prevTempIndex..prevTempIndex + registerLength-1], ancilla4, ancilla);
                        // t2 = t1 - divisor
                        QuantumSubtractor(ancilla4, divisor, ancilla2, ancilla);
                    } apply {
                        X(ancilla2[registerLength-1]);
                        // a1 = t1 - divisor ? t1 >= divisor
                        Controlled QuantumSubtractor([ancilla2[registerLength-1]], (ancilla4, divisor, tempResult[tempIndex..tempIndex + registerLength-1], ancilla));
                        X(ancilla2[registerLength-1]);
                        // a1 = t1 ? t1 < divisor
                        for t in 0..Length(ancilla4) - 1 {
                            CCNOT(ancilla2[registerLength-1], ancilla4[t], tempResult[tempIndex + t]);
                        }
                    }
                    // uncompute step
                    if (k + i) > 0 {
                        within {
                            QuantumAdder(baseValue, divisor, ancilla4, ancilla);
                            QuantumAdder(tempResult[tempIndex..tempIndex + registerLength-1], divisor, ancilla2, ancilla);
                            QuantumSubtractor(ancilla2, ancilla4, ancilla3, ancilla);
                        } apply {
                            Controlled QuantumSubtractor([ancilla3[registerLength-1]], (ancilla2, baseValue, tempResult[prevTempIndex..prevTempIndex + registerLength-1], ancilla));
                            X(ancilla3[registerLength-1]);
                            Controlled QuantumSubtractor([ancilla3[registerLength-1]], (tempResult[tempIndex..tempIndex + registerLength-1], baseValue, tempResult[prevTempIndex..prevTempIndex + registerLength-1], ancilla));
                            X(ancilla3[registerLength-1]);
                        }
                    }
                }
            }
        }
    }

    // Calculates X + Y and stores the value in outputregister
    operation QuantumAdder(inputXRegister : Qubit[], inputYRegister : Qubit[], outputRegister : Qubit[], carry : Qubit[]) : Unit is Adj + Ctl {
        for i in 0..Length(inputXRegister) {
            // calculate carry out
            if (i < Length(inputXRegister)) {
                CCNOT(inputXRegister[i], inputYRegister[i], carry[i]);
                if (i > 0) {
                    CCNOT(carry[i - 1], inputXRegister[i], carry[i]);
                    CCNOT(carry[i - 1], inputYRegister[i], carry[i]);
                }
            }

            // calculate result bit
            if (i > 0 and i < Length(outputRegister)) {
                CNOT(carry[i - 1], outputRegister[i]);
            }
            if (i < Length(inputXRegister)) {
                CNOT(inputXRegister[i], outputRegister[i]);
                CNOT(inputYRegister[i], outputRegister[i]);
            }
        }
        // uncompute carry
        for i in 0..Length(inputXRegister) - 1 {
            let j = Length(inputXRegister) - i;
            if (j > 0) {
                if (j > 1) {
                    CCNOT(carry[j - 2], inputYRegister[j - 1], carry[j - 1]);
                    CCNOT(carry[j - 2], inputXRegister[j - 1], carry[j - 1]);
                }
                CCNOT(inputXRegister[j-1], inputYRegister[j-1], carry[j-1]);
            }
        }
    }

    // subtracts value of inputYRegister from value of inputXRegister and places result in outputregister
    operation QuantumSubtractor(inputXRegister : Qubit[], inputYRegister : Qubit[], outputRegister : Qubit[], borrowBits : Qubit[]) : Unit is Adj + Ctl {
        for i in 0..Length(inputXRegister) {
            // calculate borrow out
            if (i < Length(inputXRegister)) {
                if i > 0 {
                    CCNOT(inputYRegister[i], borrowBits[i - 1], borrowBits[i]);
                    CNOT(inputYRegister[i], borrowBits[i]);
                    CNOT(borrowBits[i - 1], borrowBits[i]);
                    CCNOT(inputXRegister[i], inputYRegister[i], borrowBits[i]);
                    CCNOT(inputXRegister[i], borrowBits[i - 1], borrowBits[i]);
                } else {
                    CNOT(inputYRegister[i], borrowBits[i]);
                    CCNOT(inputXRegister[i], inputYRegister[i], borrowBits[i]);
                }
            }
            // calculate result bit
            if (i > 0 and i < Length(outputRegister)) {
                CNOT(borrowBits[i - 1], outputRegister[i]);
            }
            if (i < Length(inputXRegister)) {
                CNOT(inputXRegister[i], outputRegister[i]);
                CNOT(inputYRegister[i], outputRegister[i]);
            }
        }
        // uncompute borrow
        for i in 0..Length(inputXRegister) - 1 {
            let j = Length(inputXRegister) - i;
            if (j > 0) {
                if j > 1 {
                    CCNOT(inputXRegister[j - 1], borrowBits[j - 2], borrowBits[j - 1]);
                    CCNOT(inputXRegister[j - 1], inputYRegister[j - 1], borrowBits[j - 1]);
                    CNOT(borrowBits[j - 2], borrowBits[j - 1]);
                    CNOT(inputYRegister[j - 1], borrowBits[j - 1]);
                    CCNOT(inputYRegister[j - 1], borrowBits[j - 2], borrowBits[j - 1]);
                } else {
                    CCNOT(inputXRegister[j - 1], inputYRegister[j - 1], borrowBits[j - 1]);
                    CNOT(inputYRegister[j - 1], borrowBits[j - 1]);
                }
            }
        }
    }
}