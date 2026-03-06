using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BirthChain.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFacilityEntity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Create Facilities table first
            migrationBuilder.CreateTable(
                name: "Facilities",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    Address = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Phone = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Facilities", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Facilities_Name",
                table: "Facilities",
                column: "Name",
                unique: true);

            // 2. Insert a default facility for existing providers
            var defaultFacilityId = Guid.NewGuid();
            migrationBuilder.Sql(
                $"INSERT INTO \"Facilities\" (\"Id\", \"Name\", \"Address\", \"Phone\", \"Email\", \"CreatedAt\") " +
                $"VALUES ('{defaultFacilityId}', 'Default Facility', '', '', '', NOW()) " +
                $"ON CONFLICT DO NOTHING;");

            // 3. Drop old FacilityName, add FacilityId with default pointing to the new facility
            migrationBuilder.DropColumn(
                name: "FacilityName",
                table: "Providers");

            migrationBuilder.AddColumn<Guid>(
                name: "FacilityId",
                table: "Users",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "FacilityId",
                table: "Providers",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            // 4. Set existing providers to reference the default facility
            migrationBuilder.Sql(
                $"UPDATE \"Providers\" SET \"FacilityId\" = '{defaultFacilityId}' WHERE \"FacilityId\" = '00000000-0000-0000-0000-000000000000';");

            // 5. Add indexes and foreign keys
            migrationBuilder.CreateIndex(
                name: "IX_Users_FacilityId",
                table: "Users",
                column: "FacilityId");

            migrationBuilder.CreateIndex(
                name: "IX_Providers_FacilityId",
                table: "Providers",
                column: "FacilityId");

            migrationBuilder.AddForeignKey(
                name: "FK_Providers_Facilities_FacilityId",
                table: "Providers",
                column: "FacilityId",
                principalTable: "Facilities",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_Facilities_FacilityId",
                table: "Users",
                column: "FacilityId",
                principalTable: "Facilities",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Providers_Facilities_FacilityId",
                table: "Providers");

            migrationBuilder.DropForeignKey(
                name: "FK_Users_Facilities_FacilityId",
                table: "Users");

            migrationBuilder.DropTable(
                name: "Facilities");

            migrationBuilder.DropIndex(
                name: "IX_Users_FacilityId",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Providers_FacilityId",
                table: "Providers");

            migrationBuilder.DropColumn(
                name: "FacilityId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "FacilityId",
                table: "Providers");

            migrationBuilder.AddColumn<string>(
                name: "FacilityName",
                table: "Providers",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");
        }
    }
}
