namespace Quantum.Shor {
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
        use (x, result, divisor) = (Qubit[nBits], Qubit[nBits], Qubit[nBits]);    // for RSA the number of bits are 4096 in result
        InitializeQubitsFromInteger(2, x);
        InitializeQubitsFromInteger(N, divisor);
        InitializeQubitsFromInteger(1, result);

        // set X in superposition of all possible exponents
      //  ApplyToEach(H, x);
        
        use baseValue = Qubit[BitSizeI(a)];
        use tempMultResult = Qubit[nBits * 2];
        use tempDivisionResult = Qubit[nBits * 2];
        use tempRemainder = Qubit[nBits];
        for i in 0..Length(x) - 1 {        
            InitializeQubitsFromInteger(a, baseValue);            
            within {
                X(x[i]);         
                for j in 0..Length(baseValue) - 1 {      
                    if a % 2 == 1 {
                        CNOT(x[i], baseValue[j]);
                    }
                }                
                CNOT(x[i], baseValue[0]);                
            }
            apply {
                QuantumMultiplier(result, baseValue, tempMultResult);
                QuantumDivider(tempMultResult, divisor, tempDivisionResult, tempRemainder);
                QuantumMultiplier(result, baseValue, tempMultResult);
            }                        
            a = a ^ 2 % N;
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
    operation QuantumAdder(inputXRegister: Qubit[], inputYRegister : Qubit[], outputRegister: Qubit[]) : Unit {
        use carry = Qubit[Length(inputXRegister)];      
        QuantumAdderAdjCtl(inputXRegister, inputYRegister, outputRegister, carry);
        ResetAll(carry); 
    }

    // Calculates X + Y and stores the value in outputregister
    operation QuantumAdderAdjCtl(inputXRegister: Qubit[], inputYRegister : Qubit[], outputRegister: Qubit[], carry: Qubit[]) : Unit is Adj + Ctl {
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
    operation QuantumSubtractor(inputXRegister: Qubit[], inputYRegister: Qubit[], outputRegister: Qubit[]) : Unit {
        use borrowBits = Qubit[Length(inputXRegister)];          
        QuantumSubtractorAdjCtl(inputXRegister, inputYRegister, outputRegister, borrowBits);       
        ResetAll(borrowBits);    
    }

    // subtracts value of inputYRegister from value of inputXRegister and places result in outputregister
    operation QuantumSubtractorAdjCtl(inputXRegister: Qubit[], inputYRegister: Qubit[], outputRegister: Qubit[], borrowBits: Qubit[]) : Unit is Adj + Ctl {        
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

    //Multiplies value of multiplicand with multiplier and stores the result in outputregister. 
    operation QuantumMultiplier(multiplicandRegister: Qubit[], multiplierRegister: Qubit[], outputRegister: Qubit[]) : Unit {
        use tempRegister = Qubit[Length(multiplicandRegister) * 2];
        use tempOutputRegister =  Qubit[Length(outputRegister) * 2];
        use tempUncompute =  Qubit[Length(outputRegister)];

        for j in 0..Length(multiplierRegister) - 1 { 
            within {
                for i in 0..Length(multiplicandRegister) - 1 { 
                    CCNOT(multiplierRegister[j], multiplicandRegister[i], tempRegister[i + j]);
                }
            }
            apply {
                QuantumAdder(tempRegister, tempOutputRegister[(j % 2) * Length(outputRegister)..Length(outputRegister)-1 + (j % 2) * Length(outputRegister)], tempOutputRegister[((j + 1) % 2) * Length(outputRegister)..Length(outputRegister)-1 + ((j + 1) % 2) * Length(outputRegister)]);
            }
            // uncompute
            if (j > 0) {
                within {
                    for i in 0..Length(multiplicandRegister) - 1 { 
                        CCNOT(multiplierRegister[j - 1], multiplicandRegister[i], tempRegister[i + j - 1]);
                    }                
                }            
                apply {
                    QuantumSubtractor(tempOutputRegister[(j % 2) * Length(outputRegister)..Length(outputRegister)-1 + (j % 2) * Length(outputRegister)], tempRegister, tempUncompute);
                    QuantumAdder(tempRegister, tempUncompute, tempOutputRegister[(j % 2) * Length(outputRegister)..Length(outputRegister)-1 + (j % 2) * Length(outputRegister)]);                
                    QuantumSubtractor(tempOutputRegister[(j % 2) * Length(outputRegister)..Length(outputRegister)-1 + (j % 2) * Length(outputRegister)], tempRegister, tempUncompute);
                }
            }
        }
        // put result in output register and reset temp qubits
        ResetAll(tempRegister);   
        ResetAll(tempUncompute);
        QuantumAdder(tempOutputRegister[(Length(multiplierRegister) % 2) * Length(outputRegister)..Length(outputRegister)-1 + (Length(multiplierRegister) % 2) * Length(outputRegister)], tempUncompute, outputRegister); 
        QuantumSubtractor(outputRegister, tempUncompute, tempOutputRegister[(Length(multiplierRegister) % 2) * Length(outputRegister)..Length(outputRegister)-1 + (Length(multiplierRegister) % 2) * Length(outputRegister)]);          
        ResetAll(tempOutputRegister);
    }

    operation QuantumDivider(dividendRegister: Qubit[], divisorRegister: Qubit[], outputRegister: Qubit[], remainderRegister: Qubit[]) : Unit {
        let divisorLength = Length(divisorRegister);
        let ancillaLength = divisorLength + 1;
        use (ancillaQubits, ancillaQubits2, ancillaQubits3, ancillaQubits4, ancillaQubits5) = (Qubit[ancillaLength], Qubit[ancillaLength], Qubit[1], Qubit[ancillaLength], Qubit[ancillaLength]);
        use tempRemainderRegister = Qubit[(divisorLength + 1) * 2];
        let extendedDivisor = divisorRegister + ancillaQubits3;
       
        for j in 0..Length(dividendRegister) - 1 {
            let index = Length(dividendRegister) - 1 - j;       
            mutable workingDividend = dividendRegister[index..index];
                       
            let tempModuloIndex = (j % 2) * (divisorLength + 1);
            let prevTempModuloIndex = ((j -1) % 2) * (divisorLength + 1);
            if (j > 0) {
                workingDividend = workingDividend + tempRemainderRegister[prevTempModuloIndex..prevTempModuloIndex + divisorLength-1];
            } else {
                workingDividend =  workingDividend + ancillaQubits[0..divisorLength-1];
            }
            QuantumSubtractor(workingDividend, extendedDivisor, tempRemainderRegister[tempModuloIndex..tempModuloIndex + divisorLength]); 
         
            // substract-multiplex
            CNOT(tempRemainderRegister[tempModuloIndex + divisorLength], outputRegister[index]);
            Controlled Adjoint QuantumSubtractorAdjCtl([outputRegister[index]], (workingDividend, extendedDivisor, tempRemainderRegister[tempModuloIndex..tempModuloIndex + divisorLength], ancillaQubits2));
            Controlled QuantumAdderAdjCtl([outputRegister[index]], (workingDividend, ancillaQubits2, tempRemainderRegister[tempModuloIndex..tempModuloIndex + divisorLength], ancillaQubits4));
            X(outputRegister[index]); 
            // uncompute
            if (j > 0) {
                // recreate working dividend
                Controlled QuantumAdderAdjCtl([outputRegister[index]], (tempRemainderRegister[tempModuloIndex..tempModuloIndex + divisorLength], extendedDivisor, ancillaQubits5, ancillaQubits4));  
                within{
                    X(outputRegister[index]); 
                } 
                apply {
                    Controlled QuantumAdderAdjCtl([outputRegister[index]], (tempRemainderRegister[tempModuloIndex..tempModuloIndex + divisorLength], ancillaQubits2, ancillaQubits5, ancillaQubits4));                  
                }
                // recreate prev modulo
                CNOT(dividendRegister[index], ancillaQubits5[0]);
                let prevModulo = ancillaQubits5[1..Length(ancillaQubits5) - 1] + ancillaQubits5[0..0];
                // recreate prev working dividend
                Controlled QuantumAdderAdjCtl([outputRegister[index+1]], (prevModulo, extendedDivisor, ancillaQubits, ancillaQubits2));   
                within {
                    X(outputRegister[index+1]);
                    for i in 0..ancillaLength-1 {
                        CCNOT(outputRegister[index+1], prevModulo[i], ancillaQubits[i]);
                    }
                }
                apply
                {
                    // actual uncompute                
                    Controlled QuantumAdderAdjCtl([outputRegister[index+1]], (ancillaQubits, ancillaQubits2, tempRemainderRegister[prevTempModuloIndex..prevTempModuloIndex + divisorLength], ancillaQubits4));
                    Controlled Adjoint QuantumSubtractorAdjCtl([outputRegister[index+1]], (ancillaQubits, extendedDivisor, tempRemainderRegister[prevTempModuloIndex..prevTempModuloIndex + divisorLength], ancillaQubits4));                            
                    QuantumSubtractor(ancillaQubits, extendedDivisor, tempRemainderRegister[prevTempModuloIndex..prevTempModuloIndex + divisorLength]); 
                }
                // release ancillas
                Controlled QuantumAdderAdjCtl([outputRegister[index+1]], (prevModulo, extendedDivisor, ancillaQubits, ancillaQubits2));
                CNOT(dividendRegister[index], ancillaQubits5[0]);
                within{
                    X(outputRegister[index]); 
                } 
                apply {
                    Controlled QuantumAdderAdjCtl([outputRegister[index]], (tempRemainderRegister[tempModuloIndex..tempModuloIndex + divisorLength], ancillaQubits2, ancillaQubits5, ancillaQubits4));                  
                }
                Controlled QuantumAdderAdjCtl([outputRegister[index]], (tempRemainderRegister[tempModuloIndex..tempModuloIndex + divisorLength], extendedDivisor, ancillaQubits5, ancillaQubits4));  
            }
        }
        let tempModuloIndex = ((Length(dividendRegister) - 1) % 2) * (divisorLength + 1);
        for i in 0..Length(remainderRegister) - 1 {
            SWAP(remainderRegister[i], tempRemainderRegister[i + tempModuloIndex]);
        }
        ResetAll(ancillaQubits);
        ResetAll(ancillaQubits2); 
        ResetAll(ancillaQubits3);   
        ResetAll(ancillaQubits4); 
        ResetAll(ancillaQubits5);
        ResetAll(tempRemainderRegister);  
    }
  }