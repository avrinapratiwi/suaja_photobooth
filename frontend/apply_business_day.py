import re

with open('lib/services/firebase_service.dart', 'r') as f:
    content = f.read()

# 1. Replace getDailyReport logic
content = content.replace(
    'DateTime now = DateTime.now();\n      DateTime startOfDay = DateTime(now.year, now.month, now.day);',
    'DateTime today = BusinessDayUtils.getBusinessDay();\n      DateTime startOfDay = DateTime(today.year, today.month, today.day, 6, 0); // 06:00 AM'
)

# 2. Replace getEventSessionCountByDate logic
content = content.replace(
    'q.createdAt!.year == date.year && \n            q.createdAt!.month == date.month && \n            q.createdAt!.day == date.day',
    'BusinessDayUtils.getBusinessDayFor(q.createdAt!) == BusinessDayUtils.getBusinessDayFor(date)'
)

# 3. Replace all "final today = DateTime.now();" with "final today = BusinessDayUtils.getBusinessDay();"
content = content.replace(
    'final today = DateTime.now();',
    'final today = BusinessDayUtils.getBusinessDay();'
)

# 4. Replace todayNorm
content = content.replace(
    'final todayNorm = DateTime(today.year, today.month, today.day);',
    'final todayNorm = today;'
)

# 5. Fix manual checks for q.createdAt == today
# getTodayBoothSelesaiCount
content = content.replace(
    'return q.createdAt!.year == today.year &&\n          q.createdAt!.month == today.month &&\n          q.createdAt!.day == today.day;',
    'return BusinessDayUtils.getBusinessDayFor(q.createdAt!) == today;'
)
content = content.replace(
    'q.createdAt!.year == today.year &&\n                q.createdAt!.month == today.month &&\n                q.createdAt!.day == today.day',
    'BusinessDayUtils.getBusinessDayFor(q.createdAt!) == today'
)

# 6. Fix manual checks for cutoff
content = re.sub(
    r'final d = DateTime\(q\.createdAt!\.year, q\.createdAt!\.month, q\.createdAt!\.day\);',
    r'final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);',
    content
)

with open('lib/services/firebase_service.dart', 'w') as f:
    f.write(content)
