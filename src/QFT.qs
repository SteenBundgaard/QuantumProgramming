  namespace Quantum.QFT {
    import Std.Diagnostics.DumpMachine;
    import Microsoft.Quantum.Diagnostics.*;
    import Microsoft.Quantum.Math.*;
    import Microsoft.Quantum.Arrays.*;

   // @EntryPoint()
    operation RunQFT() : Unit {
        // Allocate 3 input qubits
        use (inputQubits, ancillaQubits) = (Qubit[1],  Qubit[1]);            
        // X(inputQubits[0]); // |1⟩
        H(inputQubits[0]); // |1⟩
        H(ancillaQubits[0]); // |1⟩
        // // inputQubits[1] is |0⟩ by default
        // X(inputQubits[2]); // |1⟩
        DumpMachine();

        let result = M(inputQubits[0]);
        DumpMachine();
 
        // Reset qubits to |0⟩ before deallocation
        ResetAll(inputQubits);
        ResetAll(ancillaQubits);  
    }
  }