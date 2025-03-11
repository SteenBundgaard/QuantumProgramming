namespace DeutschAlgorithm {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;

    operation DeutschAlgorithm (oracle : ((Qubit, Qubit) => Unit is Adj + Ctl)) : Result {
        // Allokerer to qubits
        use qubits = Qubit[2];
        let x = qubits[0]; // Input qubit
        let y = qubits[1]; // Arbejdsqubit

        // Forberedelse: Sæt y i |1⟩
        X(y);
        
        // Anvend Hadamard-gates til at skabe superposition
        H(x);
        H(y);

        // Anvend oraklet
        oracle(x, y);

        // Anvend Hadamard på input-qubit igen
        H(x);
        H(y);
        // Mål input-qubit for at afgøre funktionstypen
        let result = M(x);
        let result2 = M(y);
        // Ryd arbejdsqubit og returnér resultat
        ResetAll(qubits);

        return result;
    }

    // Eksempel på et orakel for en balanceret funktion
    operation BalancedOracle (x : Qubit, y : Qubit) : Unit is Adj + Ctl {
        CNOT(x, y); // f(x) = x
    }

    // Eksempel på et orakel for en konstant funktion
    operation ConstantOracle (x : Qubit, y : Qubit) : Unit is Adj + Ctl {
        // Ingen operation, f(x) = 0
    }

    operation ConstantOneOracle(x : Qubit, y : Qubit) : Unit is Adj + Ctl {
        X(y); // Inverter altid arbejdsqubitten
    }

 //   @EntryPoint()
    operation RunDeutschAlgorithm() : Unit {
        let resultConstant = DeutschAlgorithm(BalancedOracle);
        Message($"Constant Oracle Result: {resultConstant}");

    //     // Test med balanceret funktion
    //     let resultBalanced = DeutschAlgorithm(BalancedOracle);
    //     Message($"Balanced Oracle Result: {resultBalanced}");

    //     // Test med konstant funktion
    //     let resultConstant = DeutschAlgorithm(ConstantOracle);
    //     Message($"Constant Oracle Result: {resultConstant}");
    // }
    }
}