using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using GoldenTicket.Models;
using Microsoft.Extensions.FileProviders;

namespace GoldenTicket.Controllers;

public class HomeController(IFileProvider fileProvider) : Controller
{
    private readonly IFileProvider _fileProvider = fileProvider;

   [HttpGet("/flutter/{**path}")]
        public IActionResult FlutterAssets(string path)
        {
            // Retrieves flutter asset file

            var filePath = Path.Combine(_fileProvider.GetFileInfo("/").PhysicalPath!, path);

            if (!System.IO.File.Exists(filePath))
            {
                return NotFound();
            }

            var mimeType = "application/octet-stream";

            string extension = Path.GetExtension(filePath);
            if (extension == ".html") mimeType = "text/html";
            else if (extension == ".js") mimeType = "application/javascript";
            else if (extension == ".css") mimeType = "text/css";

            return PhysicalFile(filePath, mimeType);
        }

        [HttpGet("{**url}")]
        public IActionResult Index(string url)
        {
            // Serves the built flutter web app's index.html file
            string indexPath = _fileProvider.GetFileInfo("index.html").PhysicalPath!;

            return PhysicalFile(indexPath, "text/html");
        }
}
