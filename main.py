import requests
from bs4 import BeautifulSoup
import pdfkit
import markdown
import re
from PyPDF2 import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from io import BytesIO

def crawl_website(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')
    content = soup.get_text()
    
    simplified_content = ' '.join(content.split())
    
    return simplified_content

def generate_pdf(content, output_file):
    pdfkit.from_string(content, output_file)

def process_markdown(md_file):
    with open(md_file, 'r') as file:
        md_content = file.read()

    html_content = markdown.markdown(md_content)
    
    soup = BeautifulSoup(html_content, 'html.parser')
    important_points = []
    
    for tag in soup.find_all(['strong', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']):
        important_points.append(tag.get_text())
    
    return important_points

def highlight_pdf(input_pdf, output_pdf, highlights):
    reader = PdfReader(input_pdf)
    writer = PdfWriter()
    
    for page_num in range(len(reader.pages)):
        page = reader.pages[page_num]
        packet = BytesIO()
        can = canvas.Canvas(packet, pagesize=letter)
        
        for highlight in highlights:
            if highlight.lower() in page.extract_text().lower():
                can.setFillColorRGB(1, 1, 0, 0.5)
                can.rect(100, 100, 400, 30, fill=1, stroke=0)
        
        can.save()
        packet.seek(0)
        new_pdf = PdfReader(packet)
        page.merge_page(new_pdf.pages[0])
        writer.add_page(page)
    
    with open(output_pdf, 'wb') as output_file:
        writer.write(output_file)

def main():
    url = input("Enter the URL to crawl: ")
    content = crawl_website(url)
    pdf_file = "output.pdf"
    generate_pdf(content, pdf_file)
    print(f"PDF generated: {pdf_file}")
    
    md_file = input("Enter the path to the Markdown file: ")
    important_points = process_markdown(md_file)
    
    with open("important_points.txt", "w") as file:
        for point in important_points:
            file.write(f"- {point}\n")
    print("Important points extracted to: important_points.txt")
    
    highlighted_pdf = "highlighted_output.pdf"
    highlight_pdf(pdf_file, highlighted_pdf, important_points)
    print(f"Highlighted PDF generated: {highlighted_pdf}")

if __name__ == "__main__":
    main()