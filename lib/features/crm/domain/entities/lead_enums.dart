import 'package:flutter/material.dart';

enum LeadSource {
  call,
  email,
  website,
  others;

  String get displayName {
    switch (this) {
      case LeadSource.call:
        return 'Call';
      case LeadSource.email:
        return 'Email';
      case LeadSource.website:
        return 'Website';
      case LeadSource.others:
        return 'Others';
    }
  }

  Color get color {
    switch (this) {
      case LeadSource.call:
        return const Color(0xFF3949AB);
      case LeadSource.email:
        return const Color(0xFF0D9488);
      case LeadSource.website:
        return const Color(0xFFE65100);
      case LeadSource.others:
        return const Color(0xFF455A64);
    }
  }
}

enum LeadStage {
  newLead,
  contacted,
  proposalSent,
  disqualified,
  converted;

  String get displayName {
    switch (this) {
      case LeadStage.newLead:
        return 'New';
      case LeadStage.contacted:
        return 'Contacted';
      case LeadStage.proposalSent:
        return 'Proposal Sent';
      case LeadStage.disqualified:
        return 'Disqualified';
      case LeadStage.converted:
        return 'Converted';
    }
  }

  Color get color {
    switch (this) {
      case LeadStage.newLead:
        return const Color(0xFF3949AB);
      case LeadStage.contacted:
        return const Color(0xFFF9A825);
      case LeadStage.proposalSent:
        return const Color(0xFF0097A7);
      case LeadStage.disqualified:
        return const Color(0xFFE53935);
      case LeadStage.converted:
        return const Color(0xFF2E7D32);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case LeadStage.newLead:
        return const Color(0xFFE3F2FD);
      case LeadStage.contacted:
        return const Color(0xFFFFF9C4);
      case LeadStage.proposalSent:
        return const Color(0xFFE0F7FA);
      case LeadStage.disqualified:
        return const Color(0xFFFFEBEE);
      case LeadStage.converted:
        return const Color(0xFFE8F5E9);
    }
  }
}
