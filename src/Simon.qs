
namespace Quantum.Example {
    import Std.Diagnostics.DumpMachine;
    import Microsoft.Quantum.Diagnostics.*;
    import Microsoft.Quantum.Math.*;
    import Microsoft.Quantum.Arrays.*;
    
    /// <summary>
    /// A unitary operation that takes 3 input qubits and 2 ancilla qubits.
    /// It computes:
    /// - Parity (XOR) of the 3 input qubits and stores it in ancillaQubits[0].
    /// - AND of the first two input qubits and stores it in ancillaQubits[1].
    /// The input qubits remain unchanged.
    /// </summary>
    operation MyUnitaryOperation(inputQubits : Qubit[], ancillaQubits : Qubit[]) : Unit is Adj + Ctl {      
        let lInput = Length(inputQubits);          
        let lAncilla = Length(ancillaQubits);
        // Ensure correct number of qubits
        if (lInput != 3 or lAncilla != 2) {
            fail "Operation requires exactly 3 input qubits and 2 ancilla qubits.";
        }

        // Compute parity (XOR) of the 3 input qubits and store in ancillaQubits[0]
        for q in inputQubits {
            CNOT(q, ancillaQubits[0]);
        }
            
        CNOT(inputQubits[0], ancillaQubits[1]);
        CNOT(inputQubits[1], ancillaQubits[1]);
       
    //    X(ancillaQubits[1]);
    }

    operation ControlledResetToZero(qubit: Qubit, classicalBit: Bool) : Unit {
        if (classicalBit == false) {
            // Hvis classicalBit er 0, bring qubit i tilstanden |0⟩
            Reset(qubit);
        }
        // Hvis classicalBit er 1, gør ingenting, qubit forbliver i sin nuværende tilstand
    }

    operation SimonsOracle(inputRegister: Qubit[], outputRegister: Qubit[], s: Bool[]) : Unit {
          // Implementér oraklet
        for i in 0..Length(inputRegister) - 1 {
            if (s[i]) {
                let outputIndex = i % Length(outputRegister); // Map inputbits til outputbits
                CNOT(inputRegister[i], outputRegister[outputIndex]);
            }
        }
    }

    operation SimonsOracle2(inputRegister: Qubit[], outputRegister: Qubit[]) : Unit {
        X(outputRegister[0]);
          // Implementér oraklet
        for i in 0..Length(inputRegister) - 1 {
                CNOT(inputRegister[i], outputRegister[0]);            
        }
        for i in 0..Length(inputRegister) - 1 {
                CNOT(inputRegister[Length(inputRegister) - i - 1], outputRegister[1]);            
        }
    }

    operation SimonsOracle3(inputRegister: Qubit[], outputRegister: Qubit[]) : Unit {        
        CNOT(inputRegister[0], outputRegister[0]);            
        CNOT(inputRegister[2], outputRegister[1]); 
    }

    /// <summary>
    /// Entry point for running the MyUnitaryOperation.
    /// Allocates qubits, initializes them, runs the operation, measures ancilla qubits, and outputs the results.
    /// </summary>
  //  @EntryPoint()
    operation RunMyUnitaryOperation() : Unit {
        // Allocate 3 input qubits
        use (inputQubits, ancillaQubits) = (Qubit[3],  Qubit[2]);            
        // X(inputQubits[0]); // |1⟩
        // X(inputQubits[1]); // |1⟩
        // // inputQubits[1] is |0⟩ by default
        // X(inputQubits[2]); // |1⟩
        DumpMachine();
        for q in inputQubits {
            H(q);
        }
        DumpMachine();
        // Optionally, ensure ancilla qubits are in |0⟩
        // They are initialized to |0⟩ by default upon allocation

        // Run the unitary operation
       // MyUnitaryOperation(inputQubits, ancillaQubits);
        mutable classicalBits = [true, false, true]; // Array af 3 klassiske bits
        SimonsOracle3(inputQubits, ancillaQubits);

        DumpMachine();
        // Measure ancilla qubits to retrieve results
        let anc0 = M(ancillaQubits[0]);
        let anc1 = M(ancillaQubits[1]);
       
        // Output the measurement results
        Message($"Ancilla Qubit 0 (Parity): {anc0}");
        Message($"Ancilla Qubit 1 (AND of qubit 0 and 1): {anc1}");

        DumpMachine();

        for q in inputQubits {
            H(q);
        }

        mutable results = [Zero, size = Length(inputQubits)];
        for i in IndexRange(inputQubits) {
            set results w/= i <- M(inputQubits[i]);
        }

        // Konverter Result-array til en streng for udskrivning
        mutable resultString = "";
        for i in IndexRange(inputQubits) {
            let bit = results[i] == One ?  "1" | "0";
            set resultString += $"Qubit {i}: {bit} - ";
        }

        // Udskriv måleresultaterne
        Message(resultString);

        // Reset qubits to |0⟩ before deallocation
        ResetAll(inputQubits);
        ResetAll(ancillaQubits);           
    }
}
