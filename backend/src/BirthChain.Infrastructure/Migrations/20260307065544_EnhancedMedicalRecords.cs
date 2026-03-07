using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BirthChain.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class EnhancedMedicalRecords : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "Records",
                type: "character varying(4000)",
                maxLength: 4000,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(2000)",
                oldMaxLength: 2000);

            migrationBuilder.AddColumn<int>(
                name: "ApgarScore1Min",
                table: "Records",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ApgarScore5Min",
                table: "Records",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "BabyWeightGrams",
                table: "Records",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "BirthOutcome",
                table: "Records",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "BloodPressure",
                table: "Records",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CareInstructions",
                table: "Records",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ChiefComplaint",
                table: "Records",
                type: "character varying(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DeliveryMode",
                table: "Records",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Diagnosis",
                table: "Records",
                type: "character varying(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Examination",
                table: "Records",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "FacilityName",
                table: "Records",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "FetalHeartRate",
                table: "Records",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FetalMovement",
                table: "Records",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FetalPresentation",
                table: "Records",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "FollowUpDate",
                table: "Records",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "FollowUpRequired",
                table: "Records",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<decimal>(
                name: "FundalHeight",
                table: "Records",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "GestationalDays",
                table: "Records",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "GestationalWeeks",
                table: "Records",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Height",
                table: "Records",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Immunizations",
                table: "Records",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LabTests",
                table: "Records",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Medications",
                table: "Records",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Notes",
                table: "Records",
                type: "character varying(4000)",
                maxLength: 4000,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "OxygenSaturation",
                table: "Records",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PulseRate",
                table: "Records",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RecordType",
                table: "Records",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ReferralTo",
                table: "Records",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RespiratoryRate",
                table: "Records",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SecondaryDiagnoses",
                table: "Records",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Symptoms",
                table: "Records",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<decimal>(
                name: "Temperature",
                table: "Records",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Treatment",
                table: "Records",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "VisitDate",
                table: "Records",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<decimal>(
                name: "Weight",
                table: "Records",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Allergies",
                table: "Clients",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "BloodType",
                table: "Clients",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ChronicConditions",
                table: "Clients",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EmergencyContactName",
                table: "Clients",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EmergencyContactPhone",
                table: "Clients",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ExpectedDeliveryDate",
                table: "Clients",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Gravida",
                table: "Clients",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "HighRiskFactors",
                table: "Clients",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsHighRiskPregnancy",
                table: "Clients",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsPregnant",
                table: "Clients",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastMenstrualPeriod",
                table: "Clients",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Parity",
                table: "Clients",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PatientCategory",
                table: "Clients",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "Reminders",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProviderId = table.Column<Guid>(type: "uuid", nullable: true),
                    ReminderType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Message = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    ScheduledDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    NotifyBeforeMinutes = table.Column<int>(type: "integer", nullable: false),
                    IsRecurring = table.Column<bool>(type: "boolean", nullable: false),
                    RecurrencePattern = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    SentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RelatedRecordId = table.Column<Guid>(type: "uuid", nullable: true),
                    FacilityName = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reminders", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Reminders_Clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "Clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Reminders_Providers_ProviderId",
                        column: x => x.ProviderId,
                        principalTable: "Providers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Records_RecordType",
                table: "Records",
                column: "RecordType");

            migrationBuilder.CreateIndex(
                name: "IX_Records_VisitDate",
                table: "Records",
                column: "VisitDate");

            migrationBuilder.CreateIndex(
                name: "IX_Reminders_ClientId",
                table: "Reminders",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_Reminders_ProviderId",
                table: "Reminders",
                column: "ProviderId");

            migrationBuilder.CreateIndex(
                name: "IX_Reminders_ScheduledDate",
                table: "Reminders",
                column: "ScheduledDate");

            migrationBuilder.CreateIndex(
                name: "IX_Reminders_Status",
                table: "Reminders",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Reminders");

            migrationBuilder.DropIndex(
                name: "IX_Records_RecordType",
                table: "Records");

            migrationBuilder.DropIndex(
                name: "IX_Records_VisitDate",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "ApgarScore1Min",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "ApgarScore5Min",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "BabyWeightGrams",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "BirthOutcome",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "BloodPressure",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "CareInstructions",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "ChiefComplaint",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "DeliveryMode",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Diagnosis",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Examination",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "FacilityName",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "FetalHeartRate",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "FetalMovement",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "FetalPresentation",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "FollowUpDate",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "FollowUpRequired",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "FundalHeight",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "GestationalDays",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "GestationalWeeks",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Height",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Immunizations",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "LabTests",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Medications",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Notes",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "OxygenSaturation",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "PulseRate",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "RecordType",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "ReferralTo",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "RespiratoryRate",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "SecondaryDiagnoses",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Symptoms",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Temperature",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Treatment",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "VisitDate",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Weight",
                table: "Records");

            migrationBuilder.DropColumn(
                name: "Allergies",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "BloodType",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "ChronicConditions",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "EmergencyContactName",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "EmergencyContactPhone",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "ExpectedDeliveryDate",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "Gravida",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "HighRiskFactors",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "IsHighRiskPregnancy",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "IsPregnant",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "LastMenstrualPeriod",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "Parity",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "PatientCategory",
                table: "Clients");

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "Records",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(4000)",
                oldMaxLength: 4000);
        }
    }
}
