# Phân tích Hiệu suất & Rủi ro Nhóm Cổ phiếu Ngân hàng Niêm yết Việt Nam

**Công nghệ sử dụng:** Python (vnstock) · PostgreSQL · Power BI · Phân cụm K-means

## 1. Bối cảnh & Câu hỏi kinh doanh

### Bối cảnh
Nhóm cổ phiếu ngân hàng là một trong những nhóm ngành vốn hóa lớn nhất trên thị trường chứng khoán Việt Nam và có ảnh hưởng đáng kể đến xu hướng chung của VN-Index. Với nhà đầu tư cá nhân, việc phân biệt được mã nào tăng trưởng bền vững và mã nào tăng trưởng đi kèm rủi ro cao là bài toán thực tế, có giá trị ứng dụng trực tiếp cho quyết định đầu tư.

### Phạm vi dữ liệu

**Mã cổ phiếu (10 mã, 2 nhóm):**

| Nhóm | Mã | Ngân hàng |
|---|---|---|
| Quốc doanh | VCB | Ngân hàng TMCP Ngoại thương Việt Nam |
| Quốc doanh | BID | Ngân hàng TMCP Đầu tư và Phát triển Việt Nam |
| Quốc doanh | CTG | Ngân hàng TMCP Công Thương Việt Nam |
| Tư nhân | TCB | Ngân hàng TMCP Kỹ thương Việt Nam |
| Tư nhân | ACB | Ngân hàng TMCP Á Châu |
| Tư nhân | MBB | Ngân hàng TMCP Quân đội |
| Tư nhân | VPB | Ngân hàng TMCP Việt Nam Thịnh Vượng |
| Tư nhân | HDB | Ngân hàng TMCP Phát triển TP.HCM |
| Tư nhân | STB | Ngân hàng TMCP Sài Gòn Thương Tín |
| Tư nhân | VIB | Ngân hàng TMCP Quốc tế Việt Nam |

**Khung thời gian:**
- Dữ liệu giá & khối lượng: 02/01/2024 (phiên giao dịch đầu tiên năm 2024) - hiện tại
- Dữ liệu tài chính theo quý (P/E, ROE, EPS, NIM): Q1/2024 - Q1/2026

> **Lưu ý về mốc thời gian dữ liệu tài chính quý:** Dữ liệu tài chính quý (P/E, ROE, EPS, NIM) chỉ lấy đến Q1/2026, không lấy đến quý hiện tại như dữ liệu giá. Lý do: BCTC quý của công ty mẹ (như các ngân hàng, do có công ty con) được phép công bố tối đa 45 ngày sau khi quý kết thúc, nên tại thời điểm thu thập dữ liệu, quý gần nhất chưa chắc đã có đủ báo cáo cho cả 10 mã.

**Nguồn dữ liệu:** thư viện `vnstock` (Python) - giá đóng cửa & khối lượng giao dịch hàng ngày, chỉ số tài chính theo quý, dữ liệu VN-Index để tính beta.

### Câu hỏi kinh doanh

**Câu hỏi chính:**
Trong 10 mã cổ phiếu ngân hàng niêm yết (VCB, BID, CTG, TCB, ACB, MBB, VPB, HDB, STB, VIB) từ Q1/2024 đến nay, mã nào đang có lợi nhuận (return) cao nhưng đi kèm mức độ biến động (volatility) và rủi ro hệ thống (beta) tăng bất thường?

**Câu hỏi phụ:**
1. Biến động của nhóm cổ phiếu ngân hàng tăng/giảm rõ rệt nhất vào giai đoạn nào trong khung thời gian phân tích, và điều này có trùng với các sự kiện vĩ mô (thay đổi lãi suất, chính sách tín dụng) không?
2. Nhóm ngân hàng quốc doanh (VCB, BID, CTG) có hồ sơ rủi ro/lợi nhuận khác biệt như thế nào so với nhóm ngân hàng tư nhân (TCB, ACB, MBB, VPB, HDB, STB, VIB)?

### Vì sao câu hỏi này quan trọng
Kết quả phân tích hướng tới nhóm đối tượng là nhà đầu tư cá nhân hoặc bộ phận research của công ty chứng khoán - những người cần xác định mã nào phù hợp khẩu vị rủi ro nào, thay vì chỉ nhìn return đơn thuần. Từ đó hỗ trợ quyết định phân bổ danh mục: mã nào nên đưa vào danh mục phòng thủ, mã nào phù hợp chiến lược chấp nhận rủi ro cao hơn để đổi lấy tăng trưởng.

## 2. Thu thập dữ liệu
### Nguồn dữ liệu
- KBS (qua thư viện vnstock) - chọn nguồn này vì cung cấp đủ 4 chỉ số cần thiết (P/E, ROE, EPS, NIM), bao gồm cả NIM vốn là chỉ số đặc thù ngân hàng mà không phải nguồn nào cũng có sẵn.
- Giá KBS trả về là giá đã điều chỉnh (adjusted). Không cần tự xử lý điều chỉnh do chia tách/cổ tức
### Phạm vi thực tế đã lấy được
- Giá & khối lượng: 02/01/2024 - 09/07/2026, lấy được đủ 10 mã
- Chỉ số tài chính quý: chỉ lấy được 4 quý gần nhất
- VN-Index: 02/01/2024 - 09/07/2024
### Vấn đề gặp phải khi thu thập & cách xử lý
- Giới hạn 4 quý gần nhất ở dữ liệu tài chính (gói miễn phí): quyết định thu hẹp vai trò của nhóm chỉ số này thành "bức tranh fundamentals hiện tại" bổ trợ cho phân tích return/volatility/beta (dựa hoàn toàn trên dữ liệu giá)
- Giá trả về ở đơn vị nghìn VND: quy đổi về VND đầy đủ khi nạp vào PostgreSQL
- `trailing_eps` là EPS trượt 4 quý gần nhất (TTM), không phải EPS riêng từng quý
- Cột `2025-Q4_1` trong `ratio()` nghi là bản báo cáo trùng quý (có thể là bản đã soát xét) - để nguyên ở dữ liệu thô, xử lý sau
### Định dạng & vị trí lưu trữ
- Parquet, thư mục `raw/{price, financial, index}/`, đặt tên file theo mã cổ phiếu
