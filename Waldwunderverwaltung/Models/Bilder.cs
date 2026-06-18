using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Waldwunderverwaltung.Models
{
    [Table("Bilder")]
    public class Bilder
    {
        [Key]
        public int? Id { get; set; }

        public string Name { get; set; } = string.Empty;

        [ForeignKey("Waldwunder")]
        public int? Wonder { get; set; }

        // Navigation Property → Waldwunder
        public virtual Waldwunder? Waldwunder { get; set; }
    }
}
