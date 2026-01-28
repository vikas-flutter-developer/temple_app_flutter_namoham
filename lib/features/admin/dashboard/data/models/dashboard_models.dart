/// Dashboard data models for admin panel
/// These models parse the API responses for the admin dashboard

// ============== Dashboard Stats ==============

class DashboardStatsModel {
  final NewClientsStats newClients;
  final ActiveVisitorsStats activeVisitors;
  final RateStats conversionRate;
  final RateStats bounceRate;

  DashboardStatsModel({
    required this.newClients,
    required this.activeVisitors,
    required this.conversionRate,
    required this.bounceRate,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return DashboardStatsModel(
      newClients: NewClientsStats.fromJson(data['newClients'] ?? {}),
      activeVisitors: ActiveVisitorsStats.fromJson(data['activeVisitors'] ?? {}),
      conversionRate: RateStats.fromJson(data['conversionRate'] ?? {}),
      bounceRate: RateStats.fromJson(data['bounceRate'] ?? {}),
    );
  }
}

class NewClientsStats {
  final int total;
  final int users;
  final int temples;
  final int creators;
  final String growth;

  NewClientsStats({
    required this.total,
    required this.users,
    required this.temples,
    required this.creators,
    required this.growth,
  });

  factory NewClientsStats.fromJson(Map<String, dynamic> json) {
    return NewClientsStats(
      total: (json['total'] ?? 0) as int,
      users: (json['users'] ?? 0) as int,
      temples: (json['temples'] ?? 0) as int,
      creators: (json['creators'] ?? 0) as int,
      growth: (json['growth'] ?? '0%').toString(),
    );
  }
}

class ActiveVisitorsStats {
  final int total;
  final String status;

  ActiveVisitorsStats({required this.total, required this.status});

  factory ActiveVisitorsStats.fromJson(Map<String, dynamic> json) {
    return ActiveVisitorsStats(
      total: (json['total'] ?? 0) as int,
      status: (json['status'] ?? 'N/A').toString(),
    );
  }
}

class RateStats {
  final String rate;
  final String growth;

  RateStats({required this.rate, required this.growth});

  factory RateStats.fromJson(Map<String, dynamic> json) {
    return RateStats(
      rate: (json['rate'] ?? '0%').toString(),
      growth: (json['growth'] ?? '0%').toString(),
    );
  }
}

// ============== Monthly Engagement ==============

class MonthlyEngagementModel {
  final List<ChartDataPoint> chartData;
  final String peakMonth;
  final String growthPercentage;

  MonthlyEngagementModel({
    required this.chartData,
    required this.peakMonth,
    required this.growthPercentage,
  });

  factory MonthlyEngagementModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final chartList = (data['chartData'] as List<dynamic>?) ?? [];
    return MonthlyEngagementModel(
      chartData: chartList.map((e) => ChartDataPoint.fromJson(e)).toList(),
      peakMonth: (data['peakMonth'] ?? 'N/A').toString(),
      growthPercentage: (data['growthPercentage'] ?? '0%').toString(),
    );
  }
}

class ChartDataPoint {
  final String month;
  final num value;

  ChartDataPoint({required this.month, required this.value});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      month: (json['month'] ?? '').toString(),
      value: (json['value'] ?? 0) as num,
    );
  }
}

// ============== Traffic by Location ==============

class TrafficLocationModel {
  final String location;
  final int users;

  TrafficLocationModel({required this.location, required this.users});

  factory TrafficLocationModel.fromJson(Map<String, dynamic> json) {
    return TrafficLocationModel(
      location: (json['location'] ?? 'Unknown').toString(),
      users: (json['users'] ?? 0) as int,
    );
  }

  static List<TrafficLocationModel> fromJsonList(Map<String, dynamic> json) {
    final data = json['data'] ?? [];
    if (data is List) {
      return data.map((e) => TrafficLocationModel.fromJson(e)).toList();
    }
    return [];
  }
}

// ============== Client List ==============

class ClientModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? dateOfBirth;
  final String location;
  final String status;
  final String type;
  final DateTime? createdAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    required this.location,
    required this.status,
    required this.type,
    this.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      location: (json['location'] ?? 'N/A').toString(),
      status: (json['status'] ?? 'Offline').toString(),
      type: (json['type'] ?? 'User').toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class ClientListResponse {
  final List<ClientModel> clients;
  final PaginationModel pagination;

  ClientListResponse({required this.clients, required this.pagination});

  factory ClientListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final clientsList = (data['clients'] as List<dynamic>?) ?? [];
    return ClientListResponse(
      clients: clientsList.map((e) => ClientModel.fromJson(e)).toList(),
      pagination: PaginationModel.fromJson(data['pagination'] ?? {}),
    );
  }
}

class PaginationModel {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginationModel({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: (json['total'] ?? 0) as int,
      page: (json['page'] ?? 1) as int,
      limit: (json['limit'] ?? 20) as int,
      totalPages: (json['totalPages'] ?? 1) as int,
    );
  }
}

// ============== Donation Stats ==============

class DonationStatsModel {
  final int newDonations;
  final num totalAmount;

  DonationStatsModel({required this.newDonations, required this.totalAmount});

  factory DonationStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return DonationStatsModel(
      newDonations: (data['newDonations'] ?? 0) as int,
      totalAmount: (data['totalAmount'] ?? 0) as num,
    );
  }
}

// ============== Donation Monthly ==============

class DonationMonthlyModel {
  final List<DonationChartDataPoint> chartData;
  final String peakMonth;
  final String growthPercentage;

  DonationMonthlyModel({
    required this.chartData,
    required this.peakMonth,
    required this.growthPercentage,
  });

  factory DonationMonthlyModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final chartList = (data['chartData'] as List<dynamic>?) ?? [];
    return DonationMonthlyModel(
      chartData: chartList.map((e) => DonationChartDataPoint.fromJson(e)).toList(),
      peakMonth: (data['peakMonth'] ?? 'N/A').toString(),
      growthPercentage: (data['growthPercentage'] ?? '0%').toString(),
    );
  }
}

class DonationChartDataPoint {
  final String month;
  final num amount;
  final int count;

  DonationChartDataPoint({required this.month, required this.amount, required this.count});

  factory DonationChartDataPoint.fromJson(Map<String, dynamic> json) {
    return DonationChartDataPoint(
      month: (json['month'] ?? '').toString(),
      amount: (json['amount'] ?? 0) as num,
      count: (json['count'] ?? 0) as int,
    );
  }
}

// ============== Donation Traffic ==============

class DonationTrafficModel {
  final String location;
  final num amount;
  final int count;

  DonationTrafficModel({required this.location, required this.amount, required this.count});

  factory DonationTrafficModel.fromJson(Map<String, dynamic> json) {
    return DonationTrafficModel(
      location: (json['location'] ?? 'Unknown').toString(),
      amount: (json['amount'] ?? 0) as num,
      count: (json['count'] ?? 0) as int,
    );
  }

  static List<DonationTrafficModel> fromJsonList(Map<String, dynamic> json) {
    final data = json['data'] ?? [];
    if (data is List) {
      return data.map((e) => DonationTrafficModel.fromJson(e)).toList();
    }
    return [];
  }
}

// ============== Donation History ==============

class DonationHistoryModel {
  final String id;
  final String invoiceNo;
  final String donorName;
  final String recipientName;
  final String paymentMethod;
  final num amount;
  final DateTime? time;

  DonationHistoryModel({
    required this.id,
    required this.invoiceNo,
    required this.donorName,
    required this.recipientName,
    required this.paymentMethod,
    required this.amount,
    this.time,
  });

  factory DonationHistoryModel.fromJson(Map<String, dynamic> json) {
    return DonationHistoryModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      invoiceNo: (json['invoiceNo'] ?? json['id'] ?? '').toString(),
      donorName: (json['donorName'] ?? json['donor'] ?? 'Unknown').toString(),
      recipientName: (json['recipientName'] ?? json['recipient'] ?? 'Unknown').toString(),
      paymentMethod: (json['paymentMethod'] ?? 'N/A').toString(),
      amount: (json['amount'] ?? 0) as num,
      time: json['time'] != null ? DateTime.tryParse(json['time'].toString()) : null,
    );
  }
}

class DonationHistoryResponse {
  final List<DonationHistoryModel> donations;
  final PaginationModel pagination;

  DonationHistoryResponse({required this.donations, required this.pagination});

  factory DonationHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final donationsList = (data['donations'] as List<dynamic>?) ?? [];
    return DonationHistoryResponse(
      donations: donationsList.map((e) => DonationHistoryModel.fromJson(e)).toList(),
      pagination: PaginationModel.fromJson(data['pagination'] ?? {}),
    );
  }
}

// ============== Event Stats ==============

class EventStatsModel {
  final int totalEvents;

  EventStatsModel({required this.totalEvents});

  factory EventStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return EventStatsModel(
      totalEvents: (data['totalEvents'] ?? 0) as int,
    );
  }
}

// ============== Event List ==============

class EventModel {
  final String id;
  final String organizer;
  final String organizerId;
  final String organizerType;
  final String eventName;
  final DateTime? date;
  final String startTime;
  final String endTime;
  final String location;
  final bool isActive;

  EventModel({
    required this.id,
    required this.organizer,
    required this.organizerId,
    required this.organizerType,
    required this.eventName,
    this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.isActive,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      organizer: (json['organizer'] ?? 'Unknown').toString(),
      organizerId: (json['organizerId'] ?? '').toString(),
      organizerType: (json['organizerType'] ?? 'temple').toString(),
      eventName: (json['eventName'] ?? 'Untitled Event').toString(),
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      location: (json['location'] ?? 'N/A').toString(),
      isActive: (json['isActive'] ?? true) as bool,
    );
  }
}

class EventListResponse {
  final List<EventModel> events;
  final PaginationModel pagination;

  EventListResponse({required this.events, required this.pagination});

  factory EventListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final eventsList = (data['events'] as List<dynamic>?) ?? [];
    return EventListResponse(
      events: eventsList.map((e) => EventModel.fromJson(e)).toList(),
      pagination: PaginationModel.fromJson(data['pagination'] ?? {}),
    );
  }
}

// ============== Recent Activity ==============

class ActivityModel {
  final String activity;
  final String account;
  final String userId;
  final String relatedAccount;
  final DateTime? time;
  final String type;

  ActivityModel({
    required this.activity,
    required this.account,
    required this.userId,
    required this.relatedAccount,
    this.time,
    required this.type,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      activity: (json['activity'] ?? 'Unknown Action').toString(),
      account: (json['account'] ?? 'Unknown').toString(),
      userId: (json['userId'] ?? '').toString(),
      relatedAccount: (json['relatedAccount'] ?? '').toString(),
      time: json['time'] != null ? DateTime.tryParse(json['time'].toString()) : null,
      type: (json['type'] ?? 'User').toString(),
    );
  }
}

class ActivityListResponse {
  final List<ActivityModel> activities;
  final PaginationModel pagination;

  ActivityListResponse({required this.activities, required this.pagination});

  factory ActivityListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final activityList = (data['activities'] as List<dynamic>?) ?? [];
    return ActivityListResponse(
      activities: activityList.map((e) => ActivityModel.fromJson(e)).toList(),
      pagination: PaginationModel.fromJson(data['pagination'] ?? {}),
    );
  }
}
