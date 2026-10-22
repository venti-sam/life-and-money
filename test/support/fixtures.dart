// Made-up statements in the compact form used by pagesFromDump. They copy the
// layout of real DBS/POSB and DBS card statements, with invented names,
// numbers and amounts.

const bankDump = '''
--- page 1
[34]Account Summary as at 30 Sep 2026
[55]Deposits
[45]DBS Savings Plus Account | [271]120-3-000001 | [398]SGD | [452]201.30 | [523]201.30
[45]POSB eSavings Account | [271]149-00000-2 | [398]SGD | [444]4,490.00 | [515]4,490.00
[45]DBS Multiplier Account | [271]120-900000-4 | [398]SGD | [439]2,000.00 | [510]2,000.00
[50]CPF Investment Scheme
[45]CPFIS-OA | [265]003-000000-8-220 | [533]0.00
--- page 2
[34]Transaction Details | [253]as at 30 Sep 2026
[55]Deposits
[45]DBS Savings Plus Account | [441]Account No. 120-3-000001
[45]Date | [113]Description | [338]Withdrawal (-) | [430]Deposit (+) | [493]Balance (SGD)
[113]Balance Brought Forward | [523]201.29
[45]30/09/2026 | [113]Interest Earned | [456]0.01 | [523]201.30
[34]4 | [113]4 | [324]4 | [403]4 | [482]4
[113]Total Balance Carried Forward: | [377]0.00 | [456]0.01 | [523]201.30
[45]POSB eSavings Account | [446]Account No. 149-00000-2
[45]Date | [113]Description | [338]Withdrawal (-) | [430]Deposit (+) | [493]Balance (SGD)
[113]Balance Brought Forward | [515]1,500.00
[45]01/09/2026 | [113]Point-of-Sale Transaction | [377]10.00 | [515]1,490.00
[113]NETS QR PAYMENT 625309325544783
[113]TO: FAM ROASTED
[45]11/09/2026 | [113]Salary | [446]4,000.00 | [515]5,490.00
[113]ACME RESEARCH PTE LTD
[113]00053443
[45]12/09/2026 | [113]Funds Transfer | [372]1,000.00 | [515]4,490.00
[113]FT260912MB73119889
[113]120-900000-4:IB
[113]Balance Carried Forward | [515]4,490.00
[16]SG40020000876 (08/2014) DBS Co. Reg. No. 196800306E
[41]Transaction Details as of 30 Sep 2026 | [511]Page 2 of 9
--- page 3
[45]DBS Multiplier Account | [441]Account No. 120-900000-4
[45]Date | [113]Description | [338]Withdrawal (-) | [430]Deposit (+) | [493]Balance (SGD)
[113]Balance Brought Forward | [486]SGD 1,000.00
[45]12/09/2026 | [113]Advice Funds Transfer | [439]1,000.00 | [508]2,000.00
[113]FT260912MB73119889
[113]149-00000-2:IB
[113]Total Balance Carried Forward in SGD: | [377]0.00 | [439]1,000.00 | [508]2,000.00
[50]CPF Investment Scheme
[45]CPF Investment Account | [423]Account No. 003-000000-8-220
[45]Date | [97]Description | [338]Withdrawal (-) | [430]Deposit (+) | [493]Balance (SGD)
[97]Balance Brought Forward | [533]0.00
[45]28/09/2026 | [97]TRANSFER FROM CPF | [439]1,001.87 | [515]1,001.87
[97]Total Balance Carried Forward: | [360]0.00 | [439]1,001.87 | [533]1,001.87
''';

const cardDump = '''
--- page 1
[33]Credit Cards
[39]Statement of Account
[82]STATEMENT DATE | [220]CREDIT LIMIT | [335]MINIMUM PAYMENT | [461]PAYMENT DUE DATE
[96]12 Oct 2026 | [226]\$10,000.00 | [361]\$50.00 | [478]06 Nov 2026
[57]DATE | [124]DESCRIPTION | [502]AMOUNT (S\$)
[57]TEST VISA SIGNATURE CARD NO.: 4111 1111 1111 1234
[96]PREVIOUS BALANCE | [520]157.63 | [551]CR
[54]06 OCT | [95]BILL PAYMENT - DBS INTERNET/WIRELESS | [514]4,100.00 CR
[95]REF NO: 17912934258392788247
[54]NEW TRANSACTIONS TEST USER
[54]09 SEP | [95]BUS/MRT 926260912 | [529]3.64
[54]12 SEP | [95]NTUC FP - SHAW PLAZA | [529]4.95
--- page 2
[33]Credit Cards
[54]24 SEP | [95]AVID SPORTS SINGAPORE | [525]39.00
[54]24 SEP | [95]AVID SPORTS SINGAPORE | [525]39.00
[54]28 SEP | [95]AIRBNB * HMFP54BT9A 415-800-5959 GB | [516]1,095.29
[95]U. S. DOLLAR 828.24
[54]05 OCT | [95]SOME NEW PLACE | [529]10.00
[54]06 OCT | [95]REFUND SHOP | [514]5.00 CR
[575]SUB-TOTAL: | [640]1,191.88
[575]TOTAL: | [640]626.87
''';
