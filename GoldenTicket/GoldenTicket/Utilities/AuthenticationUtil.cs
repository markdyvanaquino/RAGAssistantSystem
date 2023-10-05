using System.Security.Cryptography;

namespace GoldenTicket.Utilities
{
    public class AuthUtils
    {
        public static string HashPassword(string password, out string salt)
        {
            byte[] saltBytes = RandomNumberGenerator.GetBytes(16);
            byte[] hashBytes = Rfc2898DeriveBytes.Pbkdf2(password, saltBytes, 100000, HashAlgorithmName.SHA256, 32);

            salt = Convert.ToBase64String(saltBytes);
            return Convert.ToBase64String(hashBytes);
        }

        public static bool VerifyPassword(string inputPassword, string storedPasswordHash)
        {
            var parts = storedPasswordHash.Split(':');
            if (parts.Length != 2) return false;

            string storedSalt = parts[0];
            string storedHash = parts[1];

            byte[] saltBytes = Convert.FromBase64String(storedSalt);
            byte[] hashBytes = Rfc2898DeriveBytes.Pbkdf2(inputPassword, saltBytes, 100000, HashAlgorithmName.SHA256, 32);
            
            return Convert.ToBase64String(hashBytes) == storedHash;
        }

    }
}