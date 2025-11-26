package com.snowCool.util;

import com.itextpdf.io.font.constants.StandardFonts;
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.kernel.colors.DeviceGray;
import com.itextpdf.kernel.colors.DeviceRgb;
import com.itextpdf.kernel.geom.PageSize;
import com.itextpdf.kernel.geom.Rectangle;
import com.itextpdf.kernel.pdf.*;
import com.itextpdf.kernel.font.PdfFont;
import com.itextpdf.kernel.font.PdfFontFactory;
import com.itextpdf.kernel.pdf.canvas.PdfCanvas;
import com.itextpdf.kernel.pdf.xobject.PdfFormXObject;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.borders.SolidBorder;
import com.itextpdf.layout.element.Cell;
import com.itextpdf.layout.element.Image;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.element.Table;
import com.itextpdf.layout.properties.TextAlignment;
import com.itextpdf.layout.properties.UnitValue;
import com.itextpdf.layout.properties.VerticalAlignment;

import com.snowCool.model.Customer;
import com.snowCool.model.CustomerInventory;
import com.snowCool.repositories.CustomerInventoryRepository;
import com.snowCool.repositories.CustomerRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.time.format.DateTimeFormatter;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Component
public class StatementGeneratorRunner implements CommandLineRunner {

    @Autowired
    private CustomerRepository customerRepository;


    @Autowired
    private CustomerInventoryRepository customerInventoryRepository;

    @Override
    public void run(String... args) throws Exception {
        // Choose a customer: try id=1, else first available, else create a placeholder
        Customer customer = null;
        Optional<Customer> opt = customerRepository.findById(1);
        if (opt.isPresent()) {
            customer = opt.get();
        } else {
            List<Customer> all = customerRepository.findAll();
            if (!all.isEmpty()) customer = all.get(0);
        }
        if (customer == null) {
            customer = new Customer();
            customer.setId(0);
            customer.setName("Fetch From Database");
            customer.setAddress("Fetch from database ...");
            customer.setContactNumber("-");
        }

        List<CustomerInventory> inventory = Collections.emptyList();
        try {
            inventory = customerInventoryRepository.findByCustomerId(customer.getId());
        } catch (Exception e) {
            // repository may throw if DB not configured; fall back to empty
            inventory = Collections.emptyList();
        }

        generatePdf(customer, inventory);
    }

    private void generatePdf(Customer customer, List<CustomerInventory> inventory) throws Exception {
        String dest = "SnowCool_Statement.pdf";
        PdfWriter writer = new PdfWriter(dest);
        PdfDocument pdf = new PdfDocument(writer);
        Document document = new Document(pdf, PageSize.A4);
        document.setMargins(36, 36, 60, 36);

        PdfFont font = PdfFontFactory.createFont(StandardFonts.HELVETICA);
        PdfFont bold = PdfFontFactory.createFont(StandardFonts.HELVETICA_BOLD);

        // Header
        float[] headerCols = {1, 4, 2};
        Table headerTable = new Table(UnitValue.createPercentArray(headerCols)).useAllAvailableWidth();
        headerTable.setBorder(null);

        // Logo
        Image logoImage = getLogoImageOrPlaceholder(pdf);
        logoImage.setAutoScale(false);
        logoImage.setWidth(50);
        logoImage.setHeight(50);
        Cell logoCell = new Cell().setBorder(null).setVerticalAlignment(VerticalAlignment.MIDDLE);
        logoCell.add(logoImage);
        headerTable.addCell(logoCell);

        // Title
        Cell titleCell = new Cell().setBorder(null).setVerticalAlignment(VerticalAlignment.MIDDLE).setTextAlignment(TextAlignment.CENTER);
        titleCell.add(new Paragraph("SnowCool Trading Co").setFont(bold).setFontSize(16f));
        headerTable.addCell(titleCell);

        // Date
        Cell dateCell = new Cell().setBorder(null).setVerticalAlignment(VerticalAlignment.MIDDLE).setTextAlignment(TextAlignment.RIGHT);
        String dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("dd-MM-yyyy"));
        dateCell.add(new Paragraph(dateStr).setFont(font).setFontSize(10f));
        headerTable.addCell(dateCell);

        document.add(headerTable);
        document.add(new Paragraph(" "));

        // Meta area
        float[] metaCols = {1, 1};
        Table metaTable = new Table(UnitValue.createPercentArray(metaCols)).useAllAvailableWidth();
        metaTable.setBorder(null);

        Cell left = new Cell().setBorder(null);
        left.add(createSmallLabelValue("Customer Name:", customer.getName(), font));
        left.add(createSmallLabelValue("Address:", customer.getAddress(), font));
        left.add(createSmallLabelValue("Account Number:", String.valueOf(customer.getId()), font));
        metaTable.addCell(left);

        Cell right = new Cell().setBorder(null).setTextAlignment(TextAlignment.RIGHT);
        right.add(new Paragraph("Available Balance:").setFont(font).setFontSize(10f));
        right.add(new Paragraph("115515.630 CR").setFont(bold).setFontSize(11f));
        metaTable.addCell(right);

        document.add(metaTable);
        document.add(new Paragraph(" "));

        // Transaction table (sample rows hard-coded as requested)
        float[] colWidths = {70f,70f,300f,90f,90f,100f};
        Table table = new Table(UnitValue.createPointArray(colWidths)).useAllAvailableWidth();
        table.setBorder(new SolidBorder(ColorConstants.BLACK, 1f));

        DeviceGray headerBg = new DeviceGray(0.9f);
        addHeaderCell(table, "Challan Date", bold, headerBg);
        addHeaderCell(table, "Challan No", bold, headerBg);
        addHeaderCell(table, "Description", bold, headerBg);
        addHeaderCell(table, "Delivered QTY", bold, headerBg, TextAlignment.RIGHT);
        addHeaderCell(table, "Retuened QTY", bold, headerBg, TextAlignment.RIGHT);
        addHeaderCell(table, "Balance", bold, headerBg, TextAlignment.RIGHT);

        List<RowData> rows = Arrays.asList(
                new RowData("01-08-23","000000","NEFTICICI000039CMS346176",164211.00,0.00,171191.04),
                new RowData("01-08-23","000001","COMM - OTHER MISC. SERVICES",118.00,0.00,171073.04),
                new RowData("01-08-23","000002","CASH Withdrawn at GCC",100.00,0.00,170973.04),
                new RowData("02-08-23","000003","UPI/DR/3213600008210/GIP Park",25.00,0.00,171048.04),
                new RowData("02-08-23","000004","UPI/DR/321306804052/VIKRANT",2519.00,0.00,168529.04),
                new RowData("02-08-23","000005","NEFT/ICICI000039*CIMS346176",15189.00,0.00,183718.04),
                new RowData("03-08-23","000006","ACH/CR HDFC00082000000891",28.00,0.00,182748.04),
                new RowData("04-08-23","000007","CHEQUE TRANSFER",150000.00,0.00,32746.04)
        );

        DeviceRgb veryLightBlue = new DeviceRgb(245,250,255);
        double totalDelivered = 0d; double totalReturned = 0d; double totalBalance = 0d;
        for (int i=0;i<rows.size();i++){
            RowData r = rows.get(i);
            boolean alternate = (i%2==1);
            com.itextpdf.kernel.colors.Color bg = alternate ? veryLightBlue : ColorConstants.WHITE;
            addBodyCell(table, r.date, font, bg);
            addBodyCell(table, r.no, font, bg);
            addBodyCell(table, r.description, font, bg);
            addBodyCellRight(table, formatDouble(r.delivered), font, bg);
            addBodyCellRight(table, formatDouble(r.returned), font, bg);
            addBodyCellRight(table, formatDouble(r.balance), font, bg);
            totalDelivered += r.delivered; totalReturned += r.returned; totalBalance += r.balance;
        }

        // Totals row
        Cell totalLabel = new Cell(1,3).add(new Paragraph("TOTAL").setFont(bold)).setTextAlignment(TextAlignment.RIGHT).setBackgroundColor(new DeviceGray(0.9f)).setPadding(6f);
        table.addCell(totalLabel);
        table.addCell(new Cell().add(new Paragraph(formatDouble(totalDelivered)).setFont(bold)).setTextAlignment(TextAlignment.RIGHT).setBackgroundColor(new DeviceGray(0.9f)).setPadding(6f));
        table.addCell(new Cell().add(new Paragraph(formatDouble(totalReturned)).setFont(bold)).setTextAlignment(TextAlignment.RIGHT).setBackgroundColor(new DeviceGray(0.9f)).setPadding(6f));
        table.addCell(new Cell().add(new Paragraph(formatDouble(totalBalance)).setFont(bold)).setTextAlignment(TextAlignment.RIGHT).setBackgroundColor(new DeviceGray(0.9f)).setPadding(6f));

        document.add(table);

        document.add(new Paragraph(" "));

        // Inventory table (from DB)
        if (inventory != null && !inventory.isEmpty()) {
            Paragraph invTitle = new Paragraph("Customer Inventory").setFont(bold).setFontSize(12f);
            document.add(invTitle);

            float[] invCols = {120f, 120f, 120f, 120f};
            Table invTable = new Table(UnitValue.createPointArray(invCols)).useAllAvailableWidth();
            addHeaderCell(invTable, "Goods Item Id", bold, headerBg, TextAlignment.RIGHT);
            addHeaderCell(invTable, "Batch Ref", bold, headerBg);
            addHeaderCell(invTable, "Qty On Loan", bold, headerBg, TextAlignment.RIGHT);
            addHeaderCell(invTable, "Last Updated", bold, headerBg, TextAlignment.RIGHT);

            boolean alt=false;
            for (CustomerInventory ci : inventory) {
                com.itextpdf.kernel.colors.Color bg = alt ? veryLightBlue : ColorConstants.WHITE;
                addBodyCellRight(invTable, ci.getGoodsItemId() == null ? "" : String.valueOf(ci.getGoodsItemId()), font, bg);
                addBodyCellRight(invTable, ci.getQtyOnLoan() == null ? "0" : String.valueOf(ci.getQtyOnLoan()), font, bg);
                addBodyCellRight(invTable, ci.getLastUpdated() == null ? "" : ci.getLastUpdated().format(DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm")), font, bg);
                alt = !alt;
            }
            document.add(invTable);
        }

        // Footer
        Paragraph footer = new Paragraph("Page No.: 1").setFont(font).setFontSize(9f);
        float x = document.getLeftMargin();
        float y = document.getBottomMargin() / 2;
        document.showTextAligned(footer, x, y, TextAlignment.LEFT);

        document.close();
        System.out.println("Generated PDF: " + dest);
    }

    private Image getLogoImageOrPlaceholder(PdfDocument pdf) {
        // To avoid compile-time dependency on com.itextpdf.io.image (which may be absent
        // in some environments), always draw a simple blue circular placeholder here.
        float size = 50f;
        PdfFormXObject xObject = new PdfFormXObject(new Rectangle(size, size));
        PdfCanvas canvas = new PdfCanvas(xObject, pdf);
        DeviceRgb blue = new DeviceRgb(0, 102, 204);
        canvas.setFillColor(blue);
        canvas.circle(size/2f, size/2f, size/2f - 0.5f);
        canvas.fill();
        return new Image(xObject);
    }

    private Paragraph createSmallLabelValue(String label, String value, PdfFont font) {
        Paragraph p = new Paragraph();
        p.setMargin(0).setPadding(0).setFont(font).setFontSize(10f);
        p.add(new com.itextpdf.layout.element.Text(label).setBold());
        p.add(new com.itextpdf.layout.element.Text(" "));
        p.add(new com.itextpdf.layout.element.Text(value == null ? "" : value));
        return p;
    }

    private void addHeaderCell(Table table, String text, PdfFont font, DeviceGray bg) {
        addHeaderCell(table, text, font, bg, TextAlignment.LEFT);
    }
    private void addHeaderCell(Table table, String text, PdfFont font, DeviceGray bg, TextAlignment align) {
        Paragraph p = new Paragraph(text).setFont(font).setFontSize(10f).setBold();
        Cell c = new Cell().add(p).setBackgroundColor(bg).setPadding(6f).setTextAlignment(align).setVerticalAlignment(VerticalAlignment.MIDDLE);
        table.addCell(c);
    }

    private void addBodyCell(Table table, String text, PdfFont font, com.itextpdf.kernel.colors.Color bg) {
        Paragraph p = new Paragraph(text == null ? "" : text).setFont(font).setFontSize(9f);
        Cell c = new Cell().add(p).setBackgroundColor(bg).setPadding(6f).setTextAlignment(TextAlignment.LEFT).setVerticalAlignment(VerticalAlignment.MIDDLE);
        table.addCell(c);
    }

    private void addBodyCellRight(Table table, String text, PdfFont font, com.itextpdf.kernel.colors.Color bg) {
        Paragraph p = new Paragraph(text == null ? "" : text).setFont(font).setFontSize(9f);
        Cell c = new Cell().add(p).setBackgroundColor(bg).setPadding(6f).setTextAlignment(TextAlignment.RIGHT).setVerticalAlignment(VerticalAlignment.MIDDLE);
        table.addCell(c);
    }

    private String formatDouble(double val) { return String.format(Locale.US, "%.2f", val); }

    private static class RowData {
        String date; String no; String description; double delivered; double returned; double balance;
        RowData(String date, String no, String description, double delivered, double returned, double balance) {
            this.date = date; this.no = no; this.description = description; this.delivered = delivered; this.returned = returned; this.balance = balance;
        }
    }
}
