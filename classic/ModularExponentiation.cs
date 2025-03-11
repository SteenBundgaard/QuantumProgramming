using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RsaTest
{
    [TestClass]
    public class Run
    {
        [TestMethod]
        public void TestNumberTheory()
        {
            var cd = 11 * 59 % (6 * 12);
            var encoded = ModularExponentiation(9, 11, 7 * 13);
            var decoded = ModularExponentiation(encoded, 59, 7 * 13);  
        }

        // Funktion til modulær eksponentiation
        static int ModularExponentiation(int baseValue, int exponent, int modulus)
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
    }
}
