namespace Quantum.ShorNew {
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

    @EntryPoint()
    operation RunModularExponentiation() : Unit {       
        let N = 7;
        mutable a = 3;
        let nBits = BitSizeI(7);
        let resultLength = nBits * 2;
        use (x, result, divisor) = (Qubit[nBits*2], Qubit[nBits*2], Qubit[nBits*2]);    // for RSA the number of bits are 4096 in result
        use remainder = Qubit[nBits * 2]; 
        use baseValue = Qubit[nBits * 2];
        use tempResult = Qubit[2*Length(result)];
        use ancilla = Qubit[Length(baseValue)];
        use ancilla2 = Qubit[Length(baseValue)];
        use ancilla3 = Qubit[Length(baseValue)];

        InitializeQubitsFromInteger(3, x);
        InitializeQubitsFromInteger(N, divisor);
        InitializeQubitsFromInteger(1, result);
   
        for v in 0..Length(x) - 1 {                
            InitializeQubitsFromInteger(a, baseValue);                        
            within {
                X(x[v]);         
                for j in 0..Length(baseValue) - 1 {      
                    if ((a &&& (1 <<< j)) != 0) {
                        CNOT(x[v], baseValue[j]);
                    }
                }                
            }                 
            apply {          
                for i in 0..Length(result) - 1 {       
                    for k in 0..(1 <<< i) - 1 {
                        let tempIndex = ((k + i) % 2) * resultLength;
                        let prevTempIndex = ((k + i + 1) % 2) * resultLength;

                        within {
                            // t1 = a0 + baseValue
                            Controlled QuantumAdder([result[i]], (baseValue, tempResult[prevTempIndex..prevTempIndex+Length(result)-1], remainder, ancilla));                                       
                            // t2 = t1 - divisor
                            Controlled QuantumSubtractor([result[i]], (remainder, divisor, ancilla2, ancilla));                                                                                                          
                        }
                        apply {
                            X(ancilla2[Length(result)-1]);
                            // a1 = t1 - divisor ? t1 >= divisor  
                            Controlled QuantumSubtractor([result[i], ancilla2[Length(result)-1]], (remainder, divisor, tempResult[tempIndex..tempIndex+Length(result)-1], ancilla));
                            X(ancilla2[Length(result)-1]);
                            // a1 = t1 ? t1 < divisor  
                            for t in 0..Length(remainder) - 1 {
                                CCNOT(ancilla2[Length(result)-1], remainder[t], tempResult[tempIndex + t]);
                            } 
                        }            
                        // uncompute step                             
                        if (k + i) > 0 {
                            within {
                                Controlled QuantumAdder([result[i]], (baseValue, divisor, remainder, ancilla));
                                Controlled QuantumAdder([result[i]], (tempResult[tempIndex..tempIndex + Length(result)-1], divisor, ancilla2, ancilla));
                                Controlled QuantumSubtractor([result[i]], (ancilla2, remainder, ancilla3, ancilla));
                            } apply {                                
                                Controlled QuantumSubtractor([result[i], ancilla3[Length(result)-1]], (ancilla2, baseValue, tempResult[prevTempIndex..prevTempIndex + Length(result)-1], ancilla));                                
                                X(ancilla3[Length(result)-1]);
                                Controlled QuantumSubtractor([result[i], ancilla3[Length(result)-1]], (tempResult[tempIndex..tempIndex + Length(result)-1], baseValue, tempResult[prevTempIndex..prevTempIndex + Length(result)-1], ancilla));
                                X(ancilla3[Length(result)-1]);  
                            }
                        }
                    } 
                }
                DumpRegister(ancilla2);
                DumpRegister(ancilla3);
                DumpRegister(remainder);     
                          DumpRegister(tempResult);  
            }
                                  
            a = (a * a) % N;
            ResetAll(baseValue);
        }
    }

    operation InitializeQubitsFromInteger(n : Int, qubits : Qubit[]) : Unit {
        ResetAll(qubits);
        let nBits = Length(qubits);
        mutable temp = n;
        // if (n < 0){
        //     X(qubits[nBits-1]);
        //     temp = 2^(nBits-1) + temp;
        // }
        for i in 0..Length(qubits) - 1 {
            if temp % 2 == 1 {
                X(qubits[i]);
            }
            temp = temp >>> 1;
        }
    }

    operation MeasureInt(qubits : Qubit[]) : Int {
        mutable bits = [];
        let nBits = Length(qubits);
        for idxBit in 0..nBits - 1 {
            set bits += [M(qubits[idxBit])];
        }
        mutable result = ResultArrayAsInt(bits);
      //  result = result - (if M(qubits[nBits - 1]) == One { 1 } else {0} ) * 2^(nBits-1);
        return result;
    }

    // Calculates X + Y and stores the value in outputregister
    operation QuantumAdder(inputXRegister: Qubit[], inputYRegister : Qubit[], outputRegister: Qubit[], carry: Qubit[]) : Unit is Adj + Ctl {
        for i in 0..Length(inputXRegister) {                        
             // calculate carry out
            if (i < Length(inputXRegister)) {
                CCNOT(inputXRegister[i], inputYRegister[i], carry[i]);
                if (i > 0)
                {            
                    CCNOT(carry[i - 1], inputXRegister[i], carry[i]);
                    CCNOT(carry[i - 1], inputYRegister[i], carry[i]);
                }
            }

            // calculate result bit
            if (i > 0 and i < Length(outputRegister)) {
                CNOT(carry[i - 1], outputRegister[i]);        
            }
            if (i < Length(inputXRegister))
            {
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
    operation QuantumSubtractor(inputXRegister: Qubit[], inputYRegister: Qubit[], outputRegister: Qubit[], borrowBits: Qubit[]) : Unit is Adj + Ctl {        
        for i in 0..Length(inputXRegister) {                        
            // calculate borrow out
            if (i < Length(inputXRegister))
            {
                if i > 0 {
                    CCNOT(inputYRegister[i], borrowBits[i - 1], borrowBits[i]);
                    CNOT(inputYRegister[i], borrowBits[i]);
                    CNOT(borrowBits[i - 1], borrowBits[i]);
                    CCNOT(inputXRegister[i], inputYRegister[i], borrowBits[i]);
                    CCNOT(inputXRegister[i], borrowBits[i - 1], borrowBits[i]);
                }
                else
                {
                    CNOT(inputYRegister[i], borrowBits[i]);
                    CCNOT(inputXRegister[i], inputYRegister[i], borrowBits[i]);
                }               
            }                   
            // calculate result bit
            if (i > 0 and i < Length(outputRegister)) {
                CNOT(borrowBits[i - 1], outputRegister[i]);        
            }
            if (i < Length(inputXRegister))
            {
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