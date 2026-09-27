import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_task.dart';
import '../bloc/lead_detail_bloc.dart';
import '../bloc/lead_detail_event.dart';
import '../bloc/lead_detail_state.dart';
import 'add_sub_task_screen.dart';
import 'add_task_screen.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class TaskDetailScreen extends StatefulWidget {
  final Lead lead;
  final LeadTask task;

  const TaskDetailScreen({super.key, required this.lead, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LeadTask _currentTask;
  late bool _isSubTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _isSubTask = _currentTask.parentId != null;
    _tabController = TabController(length: _isSubTask ? 3 : 4, vsync: this);
    // Rebuild AppBar actions when the tab changes
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTaskWith({
    List<String>? notes,
    List<String>? checklist,
  }) {
    final updatedTask = LeadTask(
      id: _currentTask.id,
      leadId: _currentTask.leadId,
      staffName: _currentTask.staffName,
      type: _currentTask.type,
      startDate: _currentTask.startDate,
      endDate: _currentTask.endDate,
      startTime: _currentTask.startTime,
      endTime: _currentTask.endTime,
      subject: _currentTask.subject,
      description: _currentTask.description,
      priority: _currentTask.priority,
      checklist: checklist ?? _currentTask.checklist,
      notes: notes ?? _currentTask.notes,
      logs: _currentTask.logs,
      parentId: _currentTask.parentId,
      createdAt: _currentTask.createdAt,
    );
    context.read<LeadDetailBloc>().add(UpdateTaskEvent(updatedTask));
    setState(() => _currentTask = updatedTask);
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWebsite(String url) async {
    if (url.isEmpty) return;
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Tab indices depend on whether this is a subtask
  // Main task:  0=Task  1=Notes  2=SubTasks  3=Logs
  // Sub task:   0=Task  1=Notes  2=Logs
  bool get _isTaskTab => _tabController.index == 0;
  bool get _isNotesTab => _tabController.index == 1;
  bool get _isSubTasksOrLogsTab =>
      _tabController.index >= (_isSubTask ? 2 : 2);

  List<Widget> _buildAppBarActions() {
    if (_isNotesTab) {
      // Notes tab — no actions
      return [];
    }
    if (_isTaskTab) {
      // Task tab — Edit button
      return [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () async {
            final edited = await Navigator.push<LeadTask>(
              context,
              MaterialPageRoute(
                builder: (_) => AddTaskScreen(
                  lead: widget.lead,
                  existingTask: _currentTask,
                ),
              ),
            );
            if (edited != null && mounted) {
              context.read<LeadDetailBloc>().add(UpdateTaskEvent(edited));
              setState(() => _currentTask = edited);
            }
          },
        ),
      ];
    }
    // Sub Tasks tab or Logs tab — Refresh only
    return [
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: () => context
            .read<LeadDetailBloc>()
            .add(LoadLeadDetail(_currentTask.leadId)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final shortId =
        _currentTask.id.length >= 3
            ? _currentTask.id.substring(_currentTask.id.length - 3)
            : _currentTask.id.padLeft(3, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Task #$shortId',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: _buildAppBarActions(),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: _isSubTask ? false : true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: [
            const Tab(text: 'Task'),
            const Tab(text: 'Notes'),
            if (!_isSubTask) const Tab(text: 'Sub Tasks'),
            const Tab(text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskTab(),
          _buildNotesTab(),
          if (!_isSubTask) _buildSubTasksTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildTaskTab() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(
      _currentTask.startDate.year,
      _currentTask.startDate.month,
      _currentTask.startDate.day,
    );

    String dateLabel;
    if (taskDate == today) {
      dateLabel = 'TODAY';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      dateLabel = 'YESTERDAY';
    } else {
      dateLabel =
          DateFormat(
            'dd MMM yyyy',
          ).format(_currentTask.startDate).toUpperCase();
    }

    final timeLabel = DateFormat('hh:mm a').format(_currentTask.startTime);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top section (Grey background)
          Container(
            color: const Color(0xFFE8EAF6),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 26, top: 2),
                  child: Text(
                    timeLabel,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Task Type Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF1A237E),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _currentTask.type.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ),
                    // Pending status & Staff Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: _kPrimaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pending',
                          style: TextStyle(
                            color: _kPrimaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _currentTask.staffName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lead Info section (White background)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.filter_alt,
                      color: Colors.black87,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: '${widget.lead.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.lead.company.isNotEmpty)
                              TextSpan(text: ', ${widget.lead.company}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (widget.lead.phone.isNotEmpty) ...[
                      _buildCircleActionButton(
                        icon: Icons.phone_outlined,
                        onTap: () => _makeCall(widget.lead.phone),
                      ),
                      const SizedBox(width: 12),
                      _buildCircleActionButton(
                        icon: Icons.chat_outlined,
                        onTap: () => _openWhatsApp(widget.lead.phone),
                      ),
                    ],
                    if (widget.lead.email.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      _buildCircleActionButton(
                        icon: Icons.email_outlined,
                        onTap: () => _sendEmail(widget.lead.email),
                      ),
                    ],
                    if (widget.lead.website.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      _buildCircleActionButton(
                        icon: Icons.public_outlined,
                        onTap: () => _openWebsite(widget.lead.website),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _kPrimaryBlue, width: 1.5),
        ),
        child: Icon(icon, color: _kPrimaryBlue, size: 20),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Text(
        'No Record Found!',
        style: const TextStyle(color: Colors.grey, fontSize: 15),
      ),
    );
  }

  final TextEditingController _noteController = TextEditingController();

  Widget _buildNotesTab() {
    return Column(
      children: [
        Expanded(
          child:
              _currentTask.notes.isEmpty
                  ? _buildPlaceholderTab('Notes')
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentTask.notes.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_currentTask.notes[index]),
                      );
                    },
                  ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Enter Note',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (_noteController.text.trim().isEmpty) return;
                  final newNotes = List<String>.from(_currentTask.notes)
                    ..add(_noteController.text.trim());
                  _updateTaskWith(notes: newNotes);
                  _noteController.clear();
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: _kPrimaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildSubTasksTab() {
    return BlocBuilder<LeadDetailBloc, LeadDetailState>(
      builder: (context, state) {
        List<LeadTask> subTasks = [];
        if (state is LeadDetailLoaded) {
          subTasks = state.tasks.where((t) => t.parentId == _currentTask.id).toList();
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sub Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (subTasks.isEmpty)
                    const Text(
                      'No sub tasks yet.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...subTasks.map((task) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<LeadDetailBloc>(),
                                child: TaskDetailScreen(
                                  lead: widget.lead,
                                  task: task,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EAF6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('hh:mm\na').format(task.startTime).toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.subject.isNotEmpty ? task.subject : 'No Subject',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF212121),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      task.type.displayName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: _kPrimaryBlue,
                onPressed: () async {
                  final newSubTask = await Navigator.push<LeadTask>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddSubTaskScreen(parentTask: _currentTask),
                    ),
                  );
                  if (newSubTask != null && mounted) {
                    context.read<LeadDetailBloc>().add(AddTaskEvent(newSubTask));
                  }
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogsTab() {
    return Stack(
      children: [
        if (_currentTask.logs.isEmpty)
          _buildPlaceholderTab('Logs')
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _currentTask.logs.length,
            itemBuilder: (context, index) {
              final log = _currentTask.logs[index];
              final date = log['date'] as String? ?? '';
              final start = log['start_time'] as String? ?? '';
              final end = log['end_time'] as String? ?? '';
              final note = log['note'] as String? ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _kPrimaryBlue,
                          ),
                        ),
                        Text(
                          '$start - $end',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(note),
                    ],
                  ],
                ),
              );
            },
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: _kPrimaryBlue,
            onPressed: () async {
              final newLog = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const AddTaskLogScreen()),
              );
              if (newLog != null && mounted) {
                context.read<LeadDetailBloc>().add(
                  AddTaskLogEvent(_currentTask.id, _currentTask.leadId, newLog),
                );
                final newLogs = List<Map<String, dynamic>>.from(
                  _currentTask.logs,
                )..add(newLog);
                setState(
                  () =>
                      _currentTask = LeadTask(
                        id: _currentTask.id,
                        leadId: _currentTask.leadId,
                        staffName: _currentTask.staffName,
                        type: _currentTask.type,
                        startDate: _currentTask.startDate,
                        endDate: _currentTask.endDate,
                        startTime: _currentTask.startTime,
                        endTime: _currentTask.endTime,
                        subject: _currentTask.subject,
                        description: _currentTask.description,
                        priority: _currentTask.priority,
                        checklist: _currentTask.checklist,
                        notes: _currentTask.notes,
                        logs: newLogs,
                        parentId: _currentTask.parentId,
                        createdAt: _currentTask.createdAt,
                      ),
                );
              }
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }


}

class AddTaskLogScreen extends StatefulWidget {
  const AddTaskLogScreen({super.key});

  @override
  State<AddTaskLogScreen> createState() => _AddTaskLogScreenState();
}

class _AddTaskLogScreenState extends State<AddTaskLogScreen> {
  DateTime _date = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveLog() {
    if (_endTime == null || _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (*)')),
      );
      return;
    }

    final dateStr = DateFormat('dd-MMM-yyyy').format(_date);
    final startStr = _startTime.format(context);
    final endStr = _endTime!.format(context);

    Navigator.pop(context, {
      'date': dateStr,
      'start_time': startStr,
      'end_time': endStr,
      'note': _noteController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Log',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabel('Date *'),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: _buildFieldContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd-MMM-yyyy').format(_date)),
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Start Time *'),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (picked != null)
                            setState(() => _startTime = picked);
                        },
                        child: _buildFieldContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_startTime.format(context)),
                              const Icon(
                                Icons.access_time,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('End Time *'),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _endTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => _endTime = picked);
                        },
                        child: _buildFieldContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_endTime?.format(context) ?? ''),
                              const Icon(
                                Icons.access_time,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel('Note *'),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
                ),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(color: Colors.grey, fontSize: 14),
          children: [
            if (text.contains('*'))
              const TextSpan(text: '*', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: child,
    );
  }
}
