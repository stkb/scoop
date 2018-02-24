using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Scoop
{
    public class Program
    {
        public static int Main(string[] args)
        {
            string schema = null;
            string[] otherArgs = args.Where(x => x != "-ci").ToArray();
            bool ci = otherArgs.Length < args.Length;
            string[] manifests = new string[0];

            if (otherArgs.Length >= 2) 
            {
                schema = otherArgs[0];
                manifests = otherArgs.Skip(1).ToArray();
            }

            if (manifests.Length == 0)
            {
                Console.WriteLine("Usage: validator.exe schema.json manifest.json");
                return 1;
            }

            Scoop.Validator validator = new Scoop.Validator(schema, ci);

            bool allValid = true;

            foreach(string manifest in manifests) 
            {
                if (validator.Validate(manifest)) 
                {
                    Console.WriteLine("Yay! {0} validates against the schema!", Path.GetFileName(manifest));
                }
                else 
                {
                    validator.Errors.ToList().ForEach(Console.WriteLine);
                    allValid = false;
                }
            }

            return allValid ? 0 : 1;
        }
    }
}
