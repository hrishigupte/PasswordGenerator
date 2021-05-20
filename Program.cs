using System;
using Nanoid;
using System.Text.RegularExpressions;
using System.IO;
namespace PasswordGenerator
{
    class Program
    {
        private static string PasswordAlphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@#$123456789";
        private static string RegexToMatchFileName ="^[a-z,A-z,1-9]*$";

         private static readonly string defaultPath = "PGenData";
        private const int DefaultPasswordSize = 9;
        static void Main(string[] args)
        {
            //Console.WriteLine("Hello World!");
            Console.WriteLine("This program generates passwords using default alphabet {0}", PasswordAlphabet);
            Console.Write("Please enter size of password required, default size is 9: ");
            string response = Console.ReadLine();
            int pwdsize;
            bool success = int.TryParse(response,out pwdsize);
            Console.WriteLine("Generating password....");
            if (!success)
                pwdsize = DefaultPasswordSize;
            string password = Nanoid.Nanoid.Generate(PasswordAlphabet,pwdsize);
            int regexmatches = 0;
            string fileName="default";
            while (regexmatches <=0)
            {
                Console.Write("Please specify a Filename (without extension) to save password, please use alphabets and numbers only, no special charecters or spaces: ");
                fileName = Console.ReadLine();
                if (String.IsNullOrEmpty(fileName))
                    continue;
                Regex reg = new Regex(RegexToMatchFileName);
                MatchCollection matches = reg.Matches(fileName);
                if (matches.Count > 0)
                {
                    break;
                }
            }

            string personalPath = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
            string pGenDataPath = "",pFilePath="";

            if (Environment.OSVersion.Platform==PlatformID.Win32NT)
            {
                pGenDataPath = (personalPath.Substring(personalPath.Length-1,1)==@"\" ? personalPath: personalPath+@"\") + defaultPath;
                //File.WriteAllText(@$"{outputfolder}\{fileName}.txt",password);
                pFilePath = pGenDataPath + @$"\{fileName}";
            }

            if ((Environment.OSVersion.Platform == PlatformID.Unix) || (Environment.OSVersion.Platform== PlatformID.Other))
            {
                pGenDataPath = (personalPath.Substring(personalPath.Length-1,1)=="/" ? personalPath: personalPath+"/") + defaultPath;
                pFilePath = pGenDataPath + @$"/{fileName}";
            }
            try
            {
                if (!Directory.Exists(pGenDataPath))
                {
                    Directory.CreateDirectory(pGenDataPath);
                }
                if (File.Exists(@$"{pFilePath}.txt"))
                {
                    Console.Write("Password file with same name already exists, please confirm if would like to proceed (yes/no):");
                    string continueResponse = Console.ReadLine();
                    if (!(continueResponse.Trim().ToLower()=="yes"))
                    {
                        Console.WriteLine("Application will exit");
                        return;
                    }
                }
               //Console.WriteLine(@$"Data will be written to Documents folder: {pFilePath}.txt");
                Console.WriteLine(@$"Output - {pFilePath}.txt");
                File.WriteAllText(@$"{pFilePath}.txt",password);
            }
            catch (UnauthorizedAccessException uaex)
            {
                Console.WriteLine("Password file cannot be stored to personal folder as application does not have permissions");
                Console.WriteLine(uaex.ToString());
            }
            catch (DirectoryNotFoundException dnex)
            {
                Console.WriteLine("Password file cannot be stored to personal folder directory for storage does not exist/cannot be created");
                Console.WriteLine(dnex.ToString());
            }
            catch (Exception ex)
            {
                Console.WriteLine("Exception while attempting to store password " + ex.ToString());
            }
        }
    }
}
