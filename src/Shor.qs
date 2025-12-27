namespace Quantum.Shor {
    import Quantum.QFT.QFT;
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
    import Quantum.Shor.*;

    @EntryPoint()
    operation RunShor() : Unit {
        let N = 15;
        let aInitial = 7;
        let nBits = BitSizeI(N);
        let registerLength = nBits + 1; // an extra bit is required for the arithemetic operations
        use (x, result) = (Qubit[registerLength * 2], Qubit[registerLength]); // for RSA the number of bits are registerLength= 4096
        // prepare with all possible values of x
        ApplyToEach(H, x);        
        // Calculates a^X mod N
        QuantumExponentiationModuloN(N, aInitial, result, x);
        // Measure exponentiation result
        let modularExponentiationResult = MeasureInt(result);
        Message($"ModularExponentiationResult = {modularExponentiationResult}");
        // QFT
        QFT(x);
        let qftOutput = Reversed(x);
        let amplitude = MeasureInt(qftOutput);
        Message($"Amplitude = {amplitude}");
        // release       
        ResetAll(result);  
        ResetAll(x);
    }
}