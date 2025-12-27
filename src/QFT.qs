  namespace Quantum.QFT {
    import Std.Convert.IntAsDouble;
    import Std.Diagnostics.DumpMachine;
    import Microsoft.Quantum.Diagnostics.*;
    import Microsoft.Quantum.Math.*;
    import Microsoft.Quantum.Arrays.*;

    operation QFT(input : Qubit[]) : Unit {
      for i in Length(input) - 1..-1..0 {
        H(input[i]);
        for j in i-1..-1..0 {
          let theta = PI() / IntAsDouble(1 <<< (i - j));
          Controlled R1([input[j]], (theta, input[i]) );
        }
      }  
    }
  }