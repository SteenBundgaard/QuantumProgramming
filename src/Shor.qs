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
    import Quantum.QFT.QFT;
    import Quantum.Shared.*;
    import Quantum.Shor.*;
    import Quantum.Random.*;

    @EntryPoint()
    operation RunShor() : Unit {
        let N = 15;
        let baseInitial = GenerateRandomBase(N);
        Message($"Random base = {baseInitial}");
        let nBits = BitSizeI(N);
        let registerLength = nBits + 1; // an extra bit is required for the arithemetic operations
        use (x, result) = (Qubit[registerLength * 2], Qubit[registerLength]); // for RSA the number of bits are registerLength= 4096
        // prepare with all possible values of x
        ApplyToEach(H, x);        
        // Calculates a^X mod N
        QuantumExponentiationModuloN(N, baseInitial, result, x);
        // Measure exponentiation result
        let modularExponentiationResult = MeasureInt(result);
        Message($"ModularExponentiationResult = {modularExponentiationResult}");
        // QFT
        QFT(x);
        let qftOutput = Reversed(x);
        let amplitude = MeasureInt(qftOutput);
        Message($"Amplitude = {amplitude}");
         // Release qubits   
        ResetAll(result);  
        ResetAll(x);
        if amplitude == 0 {
            Message($"Measurement returned zero, try again.");
            return ();
        }
        // Classical post-processing
        let fractions = ContinousFractions(amplitude, 1 <<< (2 * registerLength));
        let partialSums = CalculatePartialSums(fractions);
        // find period
        let period = FindPeriodFromPartialSums(partialSums, N, baseInitial);
        Message($"Period = {period}");
        if period % 2 != 0 {
            Message($"Bad luck - Period is odd, try again.");
            return ();
        }
        if (ClassicalModularExponentiation(baseInitial, period / 2, N) + 1) % N == 0 {
            Message($"Bad luck - (base^(period/2) + 1) mod N == 0, try again.");
            return ();
        }
        let factor1 = GreatestCommonDivisor((ClassicalModularExponentiation(baseInitial, period / 2, N) + 1) % N, N);
        let factor2 = GreatestCommonDivisor((ClassicalModularExponentiation(baseInitial, period / 2, N) - 1) % N, N);
        Message($"Congratulations. The factors are {factor1} and {factor2}. Check N = {factor1 * factor2} = {N}");            
    }

    function ContinousFractions(numerator : Int, denominator : Int) : Int[] {
        mutable cofficients = [];
        mutable tempNumerator = numerator;
        mutable tempDenominator = denominator;
        while (tempDenominator != 0) {  // will terminate for rational numbers
            let cofficient = Floor(IntAsDouble(tempNumerator) / IntAsDouble(tempDenominator));
            set cofficients += [cofficient];
            tempNumerator -= cofficient * tempDenominator;
            let temp = tempDenominator;
            tempDenominator = tempNumerator;
            tempNumerator = temp;
        }
        return cofficients;
    }

    function CalculatePartialSums(fractions : Int[]) : (Int, Int)[] {
        mutable partialSums = [];
        let fractionsBottomUp = Reversed(fractions);
        for j in 0..Length(fractionsBottomUp)-1 {
            mutable numerator = 1;
            mutable denominator = fractionsBottomUp[j];
            for i in j+1..Length(fractionsBottomUp)-1 {
                let temp = denominator;
                denominator = fractionsBottomUp[i] * denominator + numerator;
                numerator = temp;
            }
            set partialSums += [(denominator, numerator)];
        }
        return partialSums;
    }

    function FindPeriodFromPartialSums(partialSums : (Int, Int)[], N : Int, base : Int) : Int {
        for (numerator, denominator) in partialSums {
            if (denominator < N) {
                let possiblePeriod = denominator;
                for commonFactor in 1..3 {
                    if (ClassicalModularExponentiation(base, commonFactor * possiblePeriod, N) == 1) {
                        return commonFactor * possiblePeriod;
                    }
                }
            }
        }
        return 0;
    }

    function ClassicalModularExponentiation(base : Int, exponent : Int, modulus : Int) : Int {
        mutable result = 1;
        mutable baseValue = base % modulus; 
        mutable exponent = exponent;

        while (exponent > 0) {
            if ((exponent &&& 1) == 1) {
                result = (result * baseValue) % modulus;
            }

            exponent = exponent >>> 1;
            baseValue = (baseValue * baseValue) % modulus;
        }

        return result;
    }

    function GreatestCommonDivisor(a : Int, b : Int) : Int {
        mutable a = a;
        mutable b = b;
        mutable temp = 0;
        while (b != 0) {
            temp = b;
            b = a % b;
            a = temp;
        }
        return a;
    }

    operation GenerateRandomBase(N : Int) : Int {
        mutable random = 0;
        while (random == 0 or GreatestCommonDivisor(N, random) != 1) {
            random = GenerateRandomNumberInRange(N - 1);
        }
        return random;
    }
}