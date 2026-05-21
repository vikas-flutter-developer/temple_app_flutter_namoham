import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/admin/dashboard/data/models/dashboard_models.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/widgets/admin_widgets.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_main_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
class AdminDonationScreen extends StatefulWidget {
  const AdminDonationScreen({super.key});

  @override
  State<AdminDonationScreen> createState() => _AdminDonationScreenState();
}

class _AdminDonationScreenState extends State<AdminDonationScreen> {
  final ApiService _apiService = ApiService.create();
  
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  
  // Data from API
  DonationStatsModel? _stats;
  DonationMonthlyModel? _monthlyData;
  List<DonationTrafficModel> _trafficData = [];
  List<DonationHistoryModel> _donations = [];
  PaginationModel? _pagination;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final results = await Future.wait([
        _apiService.getDashboardDonationStats(filter: _selectedFilter),
        _apiService.getDonationMonthly(filter: _selectedFilter),
        _apiService.getDonationTraffic(filter: _selectedFilter),
        _apiService.getDonationHistory(filter: _selectedFilter),
      ]);
      
      setState(() {
        _stats = DonationStatsModel.fromJson(results[0]);
        _monthlyData = DonationMonthlyModel.fromJson(results[1]);
        _trafficData = DonationTrafficModel.fromJsonList(results[2]);
        final historyResponse = DonationHistoryResponse.fromJson(results[3]);
        _donations = historyResponse.donations;
        _pagination = historyResponse.pagination;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showDetailsDialog(DonationHistoryModel donation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Donation Details', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Invoice No.', donation.invoiceNo),
                const Divider(),
                _buildDetailRow('Donor', donation.donorName),
                _buildDetailRow('Recipient', donation.recipientName),
                const Divider(),
                _buildDetailRow('Amount', '₹${_formatAmount(donation.amount)}'),
                _buildDetailRow('Status', donation.status, valueColor: Colors.green),
                _buildDetailRow('Method', donation.paymentMethod),
                _buildDetailRow('Transaction ID', donation.transactionId.isEmpty ? 'N/A' : donation.transactionId),
                if (donation.time != null)
                  _buildDetailRow('Time', DateFormat('dd MMM yyyy, hh:mm a').format(donation.time!.toLocal())),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download Receipt'),
              onPressed: () {
                Navigator.pop(context);
                _downloadReceipt(donation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: valueColor ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReceipt(DonationHistoryModel donation) async {
    final pdf = pw.Document();

    // Load logo image
    final ByteData logoData = await rootBundle.load('assets/splash/namo_logo_tight.png');
    final pw.MemoryImage logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(logoImage, width: 100, height: 100),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("DONATION RECEIPT", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text("NamoHam Official", style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                      ]
                    )
                  ]
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 24),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Invoice No: ${donation.invoiceNo}'),
                  pw.Text('Date: ${donation.time != null ? DateFormat('dd MMM yyyy, hh:mm a').format(donation.time!.toLocal()) : ''}'),
                ]),
                pw.Divider(height: 32),
                pw.SizedBox(height: 16),
                pw.Text('Donor Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Name: ${donation.donorName}'),
                pw.SizedBox(height: 24),
                pw.Text('Temple/Creator Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Name: ${donation.recipientName}'),
                pw.SizedBox(height: 32),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.Column(
                    children: [
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                        pw.Text('Payment Method:'),
                        pw.Text(donation.paymentMethod),
                      ]),
                      pw.SizedBox(height: 8),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                        pw.Text('Transaction ID:'),
                        pw.Text(donation.transactionId),
                      ]),
                      pw.Divider(height: 24),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                        pw.Text('TOTAL DONATION:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs. ${_formatAmount(donation.amount)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      ]),
                    ]
                  )
                ),
                pw.SizedBox(height: 64),
                pw.Center(child: pw.Text('Thank you for your generous donation!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Receipt_${donation.invoiceNo}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          AdminHeader(
            onBackPressed: () => AdminMainLayout.switchToTab(0),
            filters: Row(
               children: [
                _buildFilterBtn("All", _selectedFilter == 'all'),
                const SizedBox(width: 12),
                _buildFilterBtn("Temple", _selectedFilter == 'temple'),
                const SizedBox(width: 12),
                _buildFilterBtn("Creator", _selectedFilter == 'creator'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Cards
                          Row(
                            children: [
                              StatCard(
                                title: "New Donation",
                                value: _stats?.newDonations.toString() ?? '0',
                                icon: Icons.group,
                                iconBgColor: const Color(0xFF00A3FF),
                                iconColor: Colors.white,
                              ),
                              const SizedBox(width: 16),
                              StatCard(
                                title: "Total Amount",
                                value: _formatAmount(_stats?.totalAmount ?? 0),
                                icon: Icons.bar_chart,
                                iconBgColor: const Color(0xFFE3F2FD),
                                iconColor: const Color(0xFF00A3FF),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Overview Chart
                           Container(
                            height: 350,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                         const Text("Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                         const SizedBox(height: 4),
                                         Text(
                                           "Donation • Peak: ${_monthlyData?.peakMonth ?? 'N/A'}", 
                                           style: const TextStyle(color: Colors.grey, fontSize: 13),
                                         ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAFAFA),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(_monthlyData?.growthPercentage ?? '0%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.trending_up, size: 16, color: Colors.green),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: _buildMonthlyBars(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column (Map)
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 524, // Matches height of (Cards + Chart + spacing)
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Donation Traffic", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      // Handle location filter
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'location', child: Text("Location")),
                                      const PopupMenuItem(value: 'temple', child: Text("Temple")),
                                      const PopupMenuItem(value: 'city', child: Text("City")),
                                    ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAFAFA),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Text("Location", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                          SizedBox(width: 4),
                                          Icon(Icons.keyboard_arrow_down, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Center(
                              child: SvgPicture.asset(
                                "assets/icons/World Map.svg",
                                width: 200,
                                placeholderBuilder: (context) => const Icon(Icons.public, size: 150, color: Colors.blueAccent),
                              ),
                            ),
                            const Spacer(),
                             Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _buildTrafficStats(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Donation History Table
                 Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Donation History (${_pagination?.total ?? 0})", 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                           Row(
                             children: [
                               const Text("Sort By", style: TextStyle(color: Colors.grey, fontSize: 12)),
                               const SizedBox(width: 8),
                               PopupMenuButton<String>(
                                onSelected: (value) {
                                  // Handle sort
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'date', child: Text("Date")),
                                  const PopupMenuItem(value: 'amount_desc', child: Text("Amount (High to Low)")),
                                  const PopupMenuItem(value: 'amount_asc', child: Text("Amount (Low to High)")),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text("Date", style: TextStyle(fontSize: 12)),
                                      SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down, size: 16),
                                    ],
                                  ),
                                ),
                               ),
                             ],
                           ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _donations.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No donation history available', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : AdminTable(
                            columns: const ["Invoice No.", "Donation From", "Donation Received", "Payment Method", "Amount", "Time", "Action"],
                            rows: _donations.map((donation) => [
                              Text(donation.invoiceNo.length > 8 ? donation.invoiceNo.substring(0, 8) : donation.invoiceNo, 
                                style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                              Text(donation.donorName, style: const TextStyle(color: Color(0xFF00A3FF), fontSize: 13)),
                              Text(donation.recipientName, style: const TextStyle(color: Color(0xFF00A3FF), fontSize: 13)),
                              Text(donation.paymentMethod, style: const TextStyle(fontSize: 13)),
                              Text("₹${_formatAmount(donation.amount)}", style: const TextStyle(fontSize: 13)),
                              Text(
                                donation.time != null 
                                  ? DateFormat('dd MMM yyyy, hh:mm a').format(donation.time!.toLocal()) 
                                  : 'N/A', 
                                style: const TextStyle(fontSize: 13),
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                                onSelected: (value) {
                                  if (value == 'view') {
                                    _showDetailsDialog(donation);
                                  } else if (value == 'download') {
                                    _downloadReceipt(donation);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'view', child: Text('View Details', style: TextStyle(fontSize: 13))),
                                  const PopupMenuItem(value: 'download', child: Text('Download Receipt', style: TextStyle(fontSize: 13))),
                                ],
                              ),
                            ]).toList(),
                          ),
                       const SizedBox(height: 16),
                       // Pagination
                       if (_pagination != null)
                         Row(
                           children: [
                             Text(
                               "${(_pagination!.page - 1) * _pagination!.limit + 1}-${_pagination!.page * _pagination!.limit} of ${_pagination!.total} items", 
                               style: TextStyle(color: Colors.grey[500], fontSize: 12),
                             ),
                             const SizedBox(width: 8),
                             PopupMenuButton<int>(
                               onSelected: (value) {
                                 // Handle page limit change
                               },
                               itemBuilder: (context) => [
                                 const PopupMenuItem(value: 10, child: Text("10/page")),
                                 const PopupMenuItem(value: 20, child: Text("20/page")),
                                 const PopupMenuItem(value: 50, child: Text("50/page")),
                               ],
                               child: Row(
                                 children: [
                                   Text("${_pagination!.limit}/page", style: TextStyle(color: Colors.grey[800], fontSize: 12)),
                                   const Icon(Icons.keyboard_arrow_down, size: 14),
                                 ],
                               ),
                             ),
                             const Spacer(),
                              const Icon(Icons.chevron_left, size: 18, color: Colors.grey),
                              const SizedBox(width: 12),
                             Text("${_pagination!.page} of ${_pagination!.totalPages}", style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 12),
                              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                           ],
                         ),
                    ],
                  ),
                 ),
                 const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
  
  List<Widget> _buildMonthlyBars() {
    if (_monthlyData == null || _monthlyData!.chartData.isEmpty) {
      return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          .map((month) => _buildBar(10, month))
          .toList();
    }
    
    final maxValue = _monthlyData!.chartData.map((e) => e.amount.toDouble()).fold<double>(1, (a, b) => a > b ? a : b);
    
    return _monthlyData!.chartData.map((point) {
      final height = maxValue > 0 ? (point.amount.toDouble() / maxValue) * 100 : 10.0;
      final isActive = point.month == _monthlyData!.peakMonth;
      return _buildBar(
        height.clamp(10.0, 100.0).toDouble(), 
        point.month,
        isActive: isActive,
        labelTop: isActive ? '₹${_formatAmount(point.amount)}' : null,
      );
    }).toList();
  }
  
  List<Widget> _buildTrafficStats() {
    if (_trafficData.isEmpty) {
      return [
        _buildTrafficStat("No Data", "0%", 0, "0 donations"),
      ];
    }
    
    final totalAmount = _trafficData.fold<num>(0, (sum, item) => sum + item.amount);
    final top3 = _trafficData.take(3).toList();
    
    return top3.map((item) {
      final percent = totalAmount > 0 ? (item.amount / totalAmount * 100).round() : 0;
      return _buildTrafficStat(
        item.location, 
        "$percent%", 
        percent / 100, 
        "${item.count} donations",
      );
    }).toList();
  }
  
  Widget _buildFilterBtn(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedFilter = title.toLowerCase();
          });
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double height, String label, {bool isActive = false, String? labelTop}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isActive && labelTop != null)
           Container(
             margin: const EdgeInsets.only(bottom: 8),
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: Colors.black,
               borderRadius: BorderRadius.circular(4),
             ),
             child: Row(
               children: [
                 const Icon(Icons.trending_up, color: Colors.greenAccent, size: 12),
                 const SizedBox(width: 4),
                 Text(labelTop, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
               ],
             ),
           ),
        Container(
          width: 30,
          height: height * 1.8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00A3FF) : const Color(0xFFF3F6FD),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTrafficStat(String name, String percentText, double percent, String details) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Progress Bar
          Container(
            height: 8,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF81D4FA),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("$percentText - $details", style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        ],
      ),
    );
  }
  
  String _formatAmount(num amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
