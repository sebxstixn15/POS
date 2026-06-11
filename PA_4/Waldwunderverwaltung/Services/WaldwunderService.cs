using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using Waldwunderverwaltung.Models;

namespace Waldwunderverwaltung.Services
{
    public class WaldwunderService
    {
        private readonly AppDbContext _db;

        public WaldwunderService(AppDbContext db)
        {
            _db = db;
        }

        // ── CREATE ────────────────────────────────────────────────────────────

        /// <summary>Creates a new Waldwunder entry and saves it to the database.</summary>
        public Waldwunder Create(string name, string description, Bundesland province,
                                 double latitude, double longitude, string type)
        {
            var item = new Waldwunder
            {
                Name = name,
                Description = description,
                Province = province,
                Latitude = latitude,
                Longitude = longitude,
                Type = type,
                Votes = 0
            };
            _db.Waldwunders.Add(item);
            _db.SaveChanges();
            return item;
        }

        /// <summary>Adds a Bilder record linking an image filename to a Waldwunder.</summary>
        public Bilder AddBild(int wunderId, string filename)
        {
            var bild = new Bilder { Wonder = wunderId, Name = filename };
            _db.Bilders.Add(bild);
            _db.SaveChanges();
            return bild;
        }

        // ── READ ──────────────────────────────────────────────────────────────

        /// <summary>Returns all Waldwunder including their associated Bilder.</summary>
        public List<Waldwunder> GetAll() =>
            _db.Waldwunders.Include(w => w.Bilder).ToList();

        /// <summary>Returns a single Waldwunder by ID, including Bilder.</summary>
        public Waldwunder? GetById(int id) =>
            _db.Waldwunders.Include(w => w.Bilder).FirstOrDefault(w => w.Id == id);

        /// <summary>Returns all Bilder records for a given Waldwunder.</summary>
        public List<Bilder> GetBilderForWunder(int wunderId) =>
            _db.Bilders.Where(b => b.Wonder == wunderId).ToList();

        // ── SEARCH (LINQ) ─────────────────────────────────────────────────────

        /// <summary>
        /// Search by keyword: returns Waldwunder whose Name or Description
        /// contains the keyword (case-insensitive).
        /// </summary>
        public List<Waldwunder> SearchByKeyword(string keyword) =>
            _db.Waldwunders
               .Include(w => w.Bilder)
               .Where(w => w.Name.Contains(keyword) || w.Description.Contains(keyword))
               .OrderBy(w => w.Name)
               .ToList();

        /// <summary>
        /// Search by type: returns all Waldwunder matching the given Art.
        /// </summary>
        public List<Waldwunder> SearchByType(string type) =>
            _db.Waldwunders
               .Include(w => w.Bilder)
               .Where(w => w.Type == type)
               .OrderBy(w => w.Name)
               .ToList();

        /// <summary>
        /// Search by location: returns all Waldwunder whose Latitude and Longitude
        /// deviate no more than ±0.5 from the given coordinates.
        /// </summary>
        public List<Waldwunder> SearchByLocation(double lat, double lon) =>
            _db.Waldwunders
               .Include(w => w.Bilder)
               .Where(w => w.Latitude  >= lat - 0.5 && w.Latitude  <= lat + 0.5
                        && w.Longitude >= lon - 0.5 && w.Longitude <= lon + 0.5)
               .OrderBy(w => w.Name)
               .ToList();

        // ── UPDATE ────────────────────────────────────────────────────────────

        public bool Update(Waldwunder item)
        {
            _db.Waldwunders.Update(item);
            return _db.SaveChanges() > 0;
        }

        // ── DELETE ────────────────────────────────────────────────────────────

        public bool Delete(int id)
        {
            var item = _db.Waldwunders.Find(id);
            if (item == null) return false;
            _db.Waldwunders.Remove(item);
            return _db.SaveChanges() > 0;
        }
    }
}
