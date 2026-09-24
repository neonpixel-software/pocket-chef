using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PocketChef.DensityApi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RenameGramsPerCupToGramsPerMilliliter : Migration
    {
        // One US customary cup in millilitres. Existing values were grams per US cup, so the
        // rename also converts them; without it an existing row would claim a flour density of 120 g/ml.
        private const string MillilitersPerUsCup = "236.5882365";

        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "GramsPerCup",
                table: "density_entries",
                newName: "GramsPerMilliliter");

            migrationBuilder.Sql(
                $"UPDATE density_entries SET \"GramsPerMilliliter\" = \"GramsPerMilliliter\" / {MillilitersPerUsCup};");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                $"UPDATE density_entries SET \"GramsPerMilliliter\" = \"GramsPerMilliliter\" * {MillilitersPerUsCup};");

            migrationBuilder.RenameColumn(
                name: "GramsPerMilliliter",
                table: "density_entries",
                newName: "GramsPerCup");
        }
    }
}
