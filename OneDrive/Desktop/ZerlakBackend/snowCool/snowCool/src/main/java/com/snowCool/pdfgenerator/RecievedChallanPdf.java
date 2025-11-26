package com.snowCool.pdfgenerator;

import com.itextpdf.io.font.constants.StandardFonts;
import com.itextpdf.io.image.ImageDataFactory;
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.kernel.font.PdfFont;
import com.itextpdf.kernel.font.PdfFontFactory;
import com.itextpdf.kernel.geom.PageSize;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.borders.Border;
import com.itextpdf.layout.borders.SolidBorder;
import com.itextpdf.layout.element.*;
import com.itextpdf.layout.properties.*;
import com.snowCool.exception.CustomException;
import com.snowCool.model.*;
import com.snowCool.repositories.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.List;

@Service
public class RecievedChallanPdf {

    private static final Logger log = LoggerFactory.getLogger(RecievedChallanPdf.class);

    @Autowired private ApplicationSettingsRepository appRepo;
    @Autowired private ChallanRepository challanRepo;
    @Autowired private ProfileRepository profileRepo;

    public byte[] generatePdfBytes(int challanId) throws Exception {
        Challan challan = challanRepo.findByIdWithItems(challanId)
                .orElseThrow(() -> new RuntimeException("Challan not found: " + challanId));

        Customer customer = challan.getCustomer();
        if (customer == null) throw new CustomException("Customer not found", HttpStatus.NOT_FOUND);

        ApplicationSettings settings = appRepo.findById(1).orElse(null);
        Profile profile = profileRepo.findById(1).orElse(null);

        return createSingleChallanPdf(customer, challan, settings, profile);
    }

    private byte[] createSingleChallanPdf(Customer customer, Challan challan,
                                          ApplicationSettings settings, Profile profile) throws Exception {

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        PdfWriter writer = new PdfWriter(baos);
        PdfDocument pdf = new PdfDocument(writer);
        Document doc = new Document(pdf, PageSize.A4);
        doc.setMargins(12, 15, 12, 15);  // slightly tighter top/bottom

        PdfFont font = PdfFontFactory.createFont(StandardFonts.HELVETICA);
        PdfFont bold = PdfFontFactory.createFont(StandardFonts.HELVETICA_BOLD);

        Table outer = new Table(1).useAllAvailableWidth()
                .setBorder(new SolidBorder(ColorConstants.BLACK, 2f))
                .setMarginTop(8);

        // ====================== HEADER ======================
        Table header = new Table(new float[]{2f, 5f, 3f}).useAllAvailableWidth().setBorder(Border.NO_BORDER);

        Cell logoCell = new Cell().setBorderRight(new SolidBorder(1f))
                .setVerticalAlignment(VerticalAlignment.MIDDLE);
        Image logo = safeImage(settings != null ? settings.getLogoBase64() : null, 110, 110);
        if (logo != null) logoCell.add(logo.setAutoScale(true));
        header.addCell(logoCell);

        Paragraph companyInfo = new Paragraph()
                .add(new Text("SNOWCOOL TRADING CO.\n").setFont(bold).setFontSize(18))
                .add(new Text(safe(profile != null ? profile.getAddress() : "") + "\n").setFont(bold).setFontSize(11))
                .add(new Text("Ph No: " + safe(profile != null ? profile.getMobileNumber() : "") + "\n").setFont(bold).setFontSize(11))
                .add(new Text("e-mail: " + safe(profile != null ? profile.getEmailId() : "")).setFont(bold).setFontSize(11))
                .setTextAlignment(TextAlignment.LEFT).setMargin(0).setPaddingLeft(5);
        header.addCell(new Cell().add(companyInfo)
                .setBorderLeft(new SolidBorder(1f)).setBorderRight(new SolidBorder(1f))
                .setVerticalAlignment(VerticalAlignment.MIDDLE));

        Paragraph title = new Paragraph()
                .add(new Text("ORIGINAL FOR RECIPIENT\n").setFont(bold).setFontSize(10))
                .add(new Text("DELIVERY CHALLAN\n").setFont(bold).setFontSize(18))
                .add(new Text("(DELIVERED)").setFont(font).setFontSize(12))
                .setTextAlignment(TextAlignment.CENTER).setMargin(0);
        header.addCell(new Cell().add(title)
                .setBorderLeft(new SolidBorder(1f))
                .setVerticalAlignment(VerticalAlignment.MIDDLE));

        outer.addCell(new Cell().add(header).setBorder(Border.NO_BORDER).setMargin(0));

        // ====================== TRANSPORT + CHALLAN INFO (ZERO GAP) ======================
     // ====================== TRANSPORT + CHALLAN INFO (PERFECT WIDTH RATIO) ======================
        Table midSection = new Table(UnitValue.createPercentArray(new float[]{50f, 50f}))  // 62% left, 38% right
                .useAllAvailableWidth()
                .setMargin(0)
                .setPadding(0);

        Paragraph transportDetails = new Paragraph()
                .add(new Text("Transport Detail :\n").setFont(bold).setFontSize(9))
                .add(new Text("Transport : ").setFontSize(9)).add(new Text(safe(challan.getTransporter()) + "\n").setFont(bold).setFontSize(9))
                .add(new Text("Driver Name : ").setFontSize(9)).add(new Text(safe(challan.getDriverName()) + "-" + safe(challan.getDriverNumber()) + "\n").setFont(bold).setFontSize(9))
                .add(new Text("Vehicle No : ").setFontSize(9)).add(new Text(safe(challan.getVehicleNumber())).setFont(bold).setFontSize(9))
                .setMargin(0);

        midSection.addCell(new Cell()
                .add(transportDetails)
                .setPadding(7)
                .setMargin(0));

        // RIGHT: Challan No + Date + Type — NARROWER (38%)
        Table rightInfo = new Table(1).useAllAvailableWidth().setMargin(0);

        Paragraph challanNoDate = new Paragraph()
                .add(new Text("Challan No : ").setFont(bold).setFontSize(9))
                .add(new Text(challan.getChallanNumber()).setFontColor(ColorConstants.BLUE).setFont(bold).setFontSize(11))
                .add(new Text("   Date : ").setFont(bold).setFontSize(9))
                .add(new Text(formatDate(challan.getDate())).setFontSize(9))
                .setTextAlignment(TextAlignment.LEFT);  // Right-align for perfect look

        rightInfo.addCell(new Cell()
                .add(challanNoDate)
                .setPadding(7)
                .setMargin(0));

        Paragraph challanTypePara = new Paragraph()
                .add(new Text("Challan Type : ").setFontSize(9))
                .add(new Text(challan.getChallanType() != null ? challan.getChallanType().name() : "N/A").setFont(bold).setFontSize(10))
                .setTextAlignment(TextAlignment.LEFT);

        rightInfo.addCell(new Cell()
                .add(challanTypePara)
                .setPadding(7)
                .setMargin(0));

        midSection.addCell(new Cell()
                .add(rightInfo)
                .setPadding(0)
                .setMargin(0));

        // Add to outer table — ZERO GAP
        outer.addCell(new Cell()
                .add(midSection)
                .setBorder(Border.NO_BORDER)
                .setMargin(0)
                .setPadding(0));
        
        
        Table custShip = new Table(UnitValue.createPercentArray(new float[]{1, 1})).useAllAvailableWidth();
        Paragraph deliveryTo = new Paragraph()
                .add(new Text("Delivery Challan For:\n").setFont(bold).setFontSize(9))
                .add(new Text(safe(customer.getName())).setFont(bold).setFontSize(9)).add("\n")
                .add("Ph no. " + safe(customer.getContactNumber())).add("\n")
                .add("E-mail : " + safe(customer.getEmail())).add("\n")
                .add(safe(customer.getAddress())).add("\n")
                .add("State: MAHARASHTRA\nState Code: 27, Country: IN").setFontSize(9);
        custShip.addCell(new Cell().add(deliveryTo).setPadding(8));

        Paragraph shippingTo = new Paragraph()
                .add(new Text("Shipping To:\n").setFont(bold).setFontSize(9))
                .add(new Text(safe(customer.getName())).setFont(bold).setFontSize(9)).add("\n")
                .add("Ph no. " + safe(customer.getContactNumber())).add("\n")
                .add("E-mail : " + safe(customer.getEmail())).add("\n")
                .add(safe(challan.getSiteLocation())).add("\n")
                .add(safe(challan.getDeliveryDetails())).setFontSize(9);
        custShip.addCell(new Cell().add(shippingTo).setPadding(8));
        outer.addCell(new Cell().add(custShip).setBorder(Border.NO_BORDER));

        // ====================== ITEMS TABLE (ZERO GAP) ======================
        Table items = new Table(new float[]{0.5f, 2.2f, 1.2f, 2f, 1f, 0.8f})
                .useAllAvailableWidth().setMarginTop(0);

        String[] headers = {"#", "Cylinder Name", "Type", "Product Sr.No", "Quantity", "Unit"};
        for (String h : headers) {
            items.addHeaderCell(new Cell().add(new Paragraph(h).setFont(bold).setFontSize(9))
                    .setBackgroundColor(ColorConstants.LIGHT_GRAY)
                    .setTextAlignment(TextAlignment.CENTER).setPadding(6).setBorder(new SolidBorder(1f)));
        }

        List<ChallanItem> itemList = challan.getItems();
        int sr = 1, totalQty = 0;
        if (itemList != null) {
            for (ChallanItem it : itemList) {
                int qty = it.getDeliveredQty(); totalQty += qty;
                items.addCell(new Cell().add(new Paragraph(String.valueOf(sr++)).setTextAlignment(TextAlignment.CENTER)).setFontSize(8));
                items.addCell(new Cell().add(new Paragraph(safe(it.getName())).setFontSize(8)));
                items.addCell(new Cell().add(new Paragraph(safe(it.getType())).setFontSize(8).setTextAlignment(TextAlignment.CENTER)));
                items.addCell(new Cell().add(new Paragraph(formatSerialNumbers(it.getSrNo())).setFontSize(8)));
                items.addCell(new Cell().add(new Paragraph(String.valueOf(qty)).setFontSize(8).setTextAlignment(TextAlignment.CENTER)));
                items.addCell(new Cell().add(new Paragraph("Nos").setTextAlignment(TextAlignment.CENTER).setFontSize(8)));
            }
        }

        items.addCell(new Cell(1,4).add(new Paragraph("Total Quantity").setFont(bold).setFontSize(9))
                .setTextAlignment(TextAlignment.CENTER).setPadding(6));
        items.addCell(new Cell().add(new Paragraph(String.valueOf(totalQty)).setFont(bold).setFontSize(9))
                .setTextAlignment(TextAlignment.CENTER).setPadding(6));
        items.addCell(new Cell());

        outer.addCell(new Cell().add(items).setBorder(Border.NO_BORDER).setMargin(0));

        // ====================== BOTTOM + FOOTER (ZERO GAPS, NEVER SPLIT) ======================
        Div finalBlock = new Div().setKeepTogether(true).setMargin(0).setPadding(0);

        Table bottom = new Table(new float[]{1f, 1f}).useAllAvailableWidth().setMargin(0);

        Cell leftCell = new Cell()
                .add(new Paragraph("GAS CYLINDER RULES 2004:").setFont(bold).setFontSize(10).setMarginBottom(6))
                .add(new Paragraph().setFontSize(7)
                        .add("1) Do Not Change the colour of this cylinder.\n")
                        .add("2) This Cylinder should be filled with any gas other than the one it now contains.\n")
                        .add("3) No flammable material should be stored in the immediate vicinity of this cylinder or in the same room in which is kept.\n")
                        .add("4) No oil or similar lubricant should be used on the valves or other fittings of this cylinder.\n")
                        .add("5) The cylinder mentioned overleaf are the property of M/s SnowCool Trading Co. and are loaned to the buyer(customer) for the use of gas there it.\n")
                        .add("6) Cylinder lost Rs.8000+GST will be charged extra.\n")
                        .add("Extra Charges: 1) Valves damages & Key damages Rs.750 plus GST\n")
                        .add("Of treatment charges extra."))
                .setPadding(10);

        Table rightSide = new Table(1).useAllAvailableWidth();
        rightSide.addCell(new Cell()
                .add(new Paragraph("Person Name & Mob No.").setFont(bold).setFontSize(9).setTextAlignment(TextAlignment.CENTER))
                .add(new Paragraph("\n\n\n\n\n").setFontSize(5))
                .setPadding(12));
        Cell signCell = new Cell()
                .setTextAlignment(TextAlignment.CENTER).setPadding(15)
                .add(new Paragraph("For SnowCool Trading Co.").setFont(bold).setFontSize(9))
                .add(new Paragraph("Authorised Signatory").setFont(bold).setFontSize(9));

        Image signatureImg = safeImage(settings != null ? settings.getSignatureBase64() : null, 140, 70);
        if (signatureImg != null) {
            signatureImg.setAutoScale(false).scaleToFit(130, 65).setHorizontalAlignment(HorizontalAlignment.CENTER);
            signCell.add(signatureImg.setMarginTop(8));
        }
        rightSide.addCell(signCell);

        bottom.addCell(leftCell).addCell(new Cell().add(rightSide).setHeight(leftCell.getHeight()));
        finalBlock.add(bottom);

        // Footer
        Paragraph footer = new Paragraph().setFontSize(9).setMargin(0);
        footer.add(new Text("Ph: ").setFont(bold))
              .add(new Text(safe(profile != null ? profile.getMobileNumber() : "") + "   "));
        footer.add(new Tab()).addTabStops(new TabStop(1000, TabAlignment.RIGHT));
        footer.add(new Text("You may write to us with your feedback at: ").setFont(font))
              .add(new Text(safe(profile != null ? profile.getEmailId() : "")).setFont(bold));

        finalBlock.add(new Cell().add(footer)
                .setBorderTop(new SolidBorder(1f)).setPaddingTop(6).setPaddingBottom(6));

        outer.addCell(new Cell().add(finalBlock).setBorder(Border.NO_BORDER).setMargin(0));

        doc.add(outer);
        doc.close();
        return baos.toByteArray();
    }

    // HELPER METHODS (unchanged)
    private String formatSerialNumbers(String[] srNos) {
        return (srNos == null || srNos.length == 0) ? "-" : String.join(" / ", srNos);
    }
    private String formatDate(String dateStr) {
        try { return LocalDate.parse(dateStr).format(DateTimeFormatter.ofPattern("dd/MM/yyyy")); }
        catch (Exception e) { return dateStr; }
    }
    private String safe(String s) { return s == null ? "" : s.trim(); }
    private Image safeImage(String base64, float w, float h) {
        if (base64 == null || base64.trim().isEmpty()) return null;
        try {
            String clean = base64.trim();
            if (clean.contains(",")) clean = clean.split(",")[1];
            clean += "=".repeat((4 - clean.length() % 4) % 4);
            byte[] bytes = Base64.getDecoder().decode(clean);
            Image img = new Image(ImageDataFactory.create(bytes));
            img.scaleToFit(w, h);
            return img;
        } catch (Exception e) { log.warn("Image load failed", e); return null; }
    }
}