using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.IO;
using System.Linq;

namespace Example
{
    public class CharacterData
    {
        public string Url { get; set; }
        public string Name { get; set; }
        public string Gender { get; set; }
        public string Species { get; set; }
        public string Photo { get; set; }
    }

    public class Series
    {
        public int Id { get; set; }

        [Required]
        public string Name { get; set; }

        [Required]
        public ICollection<Character> Characters { get; set; }
    }

    public class Character
    {
        public int Id { get; set; }

        [Required]
        public string Name { get; set; }

        public string Gender { get; set; }

        [Required]
        public string Species { get; set; }

        [Required]
        public Series Series { get; set; }

        public CharacterPhoto Photo { get; set; }
    }

    public class CharacterPhoto
    {
        public int Id { get; set; }

        [Required]
        public Character Character { get; set; }

        [Required]
        public byte[] Photo { get; set; }
    }

    public class StarTrekContext : DbContext
    {
        private readonly string _connectionString;

        public DbSet<Series> Series { get; set; }
        public DbSet<Character> Characters { get; set; }

        public StarTrekContext(string connectionString)
        {
            _connectionString = connectionString;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseNpgsql(_connectionString);
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // NB while upgrading to ef-core 2.1 we noticed that this one-to-one mapping
            //    was not really ideal, but for data backward-compatibility, we leave it
            //    as it was originally.
            modelBuilder.Entity<CharacterPhoto>()
                .HasOne(cp => cp.Character)
                .WithOne(c => c.Photo)
                .HasForeignKey<Character>("PhotoId");
        }
    }

    // this is used when you run a design-time command, e.g.:
    //      dotnet ef migrations add InitialCreate
    //      dotnet ef migrations add AddCharacterPhoto
    //      dotnet ef database update
    // see https://docs.microsoft.com/en-us/ef/core/miscellaneous/cli/dbcontext-creation
    public class StarTrekContextFactory : IDesignTimeDbContextFactory<StarTrekContext>
    {
        // NB args is always empty.
        //    see https://github.com/aspnet/EntityFrameworkCore/issues/8332
        public StarTrekContext CreateDbContext(string[] args)
        {
            var connectionString = "Host=postgresql.example.com; Port=5432; SSL Mode=VerifyFull; Username=postgres; Password=postgres; Database=StarTrekEfCore";

            return new StarTrekContext(connectionString);
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            // see https://docs.microsoft.com/en-us/ef/core/
            // see http://www.npgsql.org/efcore/
            // see http://www.npgsql.org/doc/connection-string-parameters.html
            // see http://www.npgsql.org/doc/security.html
            // NB npgsql uses the native windows Trusted Root Certification Authorities store to validate the server certificate.
            var connectionString = "Host=postgresql.example.com; Port=5432; SSL Mode=Disable; Username=postgres; Password=postgres; Database=StarTrekEfCore";
            var connectionStringSsl = connectionString.Replace("SSL Mode=Disable", "SSL Mode=VerifyFull");

            using (var db = new StarTrekContext(connectionStringSsl))
            {
                if (!db.Series.Any())
                {
                    Console.WriteLine("Populating the database");

                    var data = JsonConvert.DeserializeObject<Dictionary<string, CharacterData[]>>(File.ReadAllText("star-trek-scraper/data.json"));

                    foreach (var kp in data)
                    {
                        var series = new Series
                        {
                            Name = kp.Key,
                            Characters = new List<Character>(),
                        };
                        db.Series.Add(series);

                        foreach (var c in kp.Value.OrderBy(d => d.Name))
                        {
                            Console.WriteLine("Adding {0} ({1}) to the database", c.Name, series.Name);

                            series.Characters.Add(
                                new Character
                                {
                                    Name = c.Name,
                                    Gender = c.Gender,
                                    Species = c.Species,
                                    Photo = new CharacterPhoto { Photo = Convert.FromBase64String(c.Photo) },
                                }
                            );
                        }
                    }

                    var count = db.SaveChanges();

                    Console.WriteLine("{0} records saved to the database", count);
                }
            }

            using (var db = new StarTrekContext(connectionString))
            {
                Console.WriteLine("Star Trek Characters:");

                foreach (var c in db.Characters.Include(c => c.Series).OrderBy(c => c.Name))
                {
                    Console.WriteLine("    {0} ({1}; {2})", c.Name, (c.Gender ?? "").Replace("\n", "; "), c.Series.Name);
                }
            }
        }
    }
}
