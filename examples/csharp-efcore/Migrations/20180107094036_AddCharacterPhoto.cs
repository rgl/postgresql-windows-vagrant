using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;
using System;
using System.Collections.Generic;

namespace Example.Migrations
{
    public partial class AddCharacterPhoto : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "PhotoId",
                table: "Characters",
                type: "int4",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "CharacterPhoto",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int4", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.SerialColumn),
                    Photo = table.Column<byte[]>(type: "bytea", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CharacterPhoto", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Characters_PhotoId",
                table: "Characters",
                column: "PhotoId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Characters_CharacterPhoto_PhotoId",
                table: "Characters",
                column: "PhotoId",
                principalTable: "CharacterPhoto",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Characters_CharacterPhoto_PhotoId",
                table: "Characters");

            migrationBuilder.DropTable(
                name: "CharacterPhoto");

            migrationBuilder.DropIndex(
                name: "IX_Characters_PhotoId",
                table: "Characters");

            migrationBuilder.DropColumn(
                name: "PhotoId",
                table: "Characters");
        }
    }
}
