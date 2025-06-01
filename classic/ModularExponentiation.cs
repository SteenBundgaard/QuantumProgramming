//using Microsoft.VisualStudio.TestTools.UnitTesting;
using RsaTest;

var cd = 11 * 59 % (6 * 12);
var encoded = Run.ModularExponentiation(9, 11, 7 * 13);
var encoded2 = Run.ModularExponentiation2(9, 11, 7 * 13);
var encoded3 = Run.ModularExponentiation3(9, 11, 7 * 13);
var a = 42;            

namespace RsaTest
{
  //  [TestClass]
    public class Run
    {
//     [TestMethod]
        public void TestNumberTheory()
        {
            var cd = 11 * 59 % (6 * 12);
            var encoded = ModularExponentiation2(9, 11, 7 * 13);
            var decoded = ModularExponentiation(encoded, 59, 7 * 13);  
        }

        // Funktion til modulær eksponentiation
        public static int ModularExponentiation(int baseValue, int exponent, int modulus)
        {
            int result = 1;
            baseValue = baseValue % modulus; // Reducer basen mod modulus

            while (exponent > 0)
            {
                // Hvis eksponenten er ulige, multiplicér med resultatet
                if ((exponent & 1) == 1)
                {
                    result = (result * baseValue) % modulus;
                }

                // Eksponent halveres, og baseValue kvadreres
                exponent = exponent >> 1;
                baseValue = (baseValue * baseValue) % modulus;
            }

            return result;
        }

        public static int ModularExponentiation2(int baseValue, int exponent, int modulus)
        {
            int result = 1;
            baseValue = baseValue % modulus; // Reducer basen mod modulus

            while (exponent > 0)
            {
                // Hvis eksponenten er ulige, multiplicér med resultatet
                if ((exponent & 1) == 1)
                {
                    int tmp = 0;
                    for (var i = 0; i < result; i++)
                    {
                        tmp += baseValue;
                        tmp = tmp % modulus;
                    };
                    result = tmp;
                }

                // Eksponent halveres, og baseValue kvadreres
                exponent = exponent >> 1;
                baseValue = baseValue * baseValue % modulus;
            }

            return result;
        }

        public static int ModularExponentiation3(int baseValue, int exponent, int modulus)
        {
            int result = 1;
            baseValue = baseValue % modulus; // Reducer basen mod modulus

            while (exponent > 0)
            {
                // Hvis eksponenten er ulige, multiplicér med resultatet
                if ((exponent & 1) == 1)
                {
                    int tmp = 0;
                    for (var i = 0; i < System.Math.Log2(result) + 1; i++)
                    {
                        if ((result & Convert.ToInt32(System.Math.Pow(2, i))) == 1)
                        {
                            for (var j = 0; j < Math.Pow(2,i); j++)
                            {
                                tmp += baseValue;
                                tmp = tmp % modulus;
                            }
                        }                        
                    }                    
                    result = tmp;
                }

                // Eksponent halveres, og baseValue kvadreres
                exponent = exponent >> 1;
                baseValue = baseValue * baseValue % modulus;
            }

            return result;
        }
    }
}
