using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Waldwunderverwaltung.Models
{
    [Table("Waldwunder")]
    public class Waldwunder
    {
        [Key]
        public int? Id { get; set; }

        public string Name { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;

        public Bundesland Province { get; set; }

        public double Latitude { get; set; }

        public double Longitude { get; set; }

        public string Type { get; set; } = string.Empty;

        public int Votes { get; set; }

        // Navigation property
        public virtual ICollection<Bilder> Bilder { get; set; } = new List<Bilder>();
    }
}
