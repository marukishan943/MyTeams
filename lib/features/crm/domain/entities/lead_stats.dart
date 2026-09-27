import 'package:equatable/equatable.dart';

class LeadStats extends Equatable {
  final int newCount;
  final int contactedCount;
  final int proposalSentCount;
  final int disqualifiedCount;
  final int convertedCount;

  const LeadStats({
    this.newCount = 0,
    this.contactedCount = 0,
    this.proposalSentCount = 0,
    this.disqualifiedCount = 0,
    this.convertedCount = 0,
  });

  int get total =>
      newCount +
      contactedCount +
      proposalSentCount +
      disqualifiedCount +
      convertedCount;

  @override
  List<Object?> get props => [
        newCount,
        contactedCount,
        proposalSentCount,
        disqualifiedCount,
        convertedCount,
      ];
}
