import '../models/isar_models.dart';
import '../services/split_service.dart';

class SampleData {
  static Future<void> load(Isar isar) async {
    await isar.writeTxn(() async {
      // 1. Clear expenses, groups, and settlements
      await isar.collection<Expense>().clear();
      await isar.collection<Group>().clear();
      await isar.collection<Settlement>().clear();

      // 2. Fetch or create members
      List<Member> members = await isar.collection<Member>().where().findAll();

      // Identify current user
      Member currentMember = members.firstWhere(
        (m) => m.isCurrentUser,
        orElse: () => Member(
          name: 'You',
          initials: 'Y',
          email: 'you@univ.edu',
          colorValue: 0xFF3B82F6,
          isCurrentUser: true,
        ),
      );
      if (currentMember.id == Isar.autoIncrement) {
        await isar.collection<Member>().put(currentMember);
      }

      // Create Evaluator Demo Members
      Member arun = await _getOrCreateMember(isar, 'Arun', 'AS', 0xFF10B981);
      Member priya = await _getOrCreateMember(isar, 'Priya', 'PY', 0xFFF59E0B);
      Member rahul = await _getOrCreateMember(isar, 'Rahul', 'RV', 0xFFEF4444);
      Member venkat = await _getOrCreateMember(
        isar,
        'Venkatesh',
        'VS',
        0xFF8B5CF6,
      );

      // 3. Create Groups
      final collegeFriends = Group()
        ..name = 'College Friends'
        ..icon = '🎓'
        ..createdAt = DateTime.now().subtract(const Duration(days: 30));

      final dailyCommute = Group()
        ..name = 'Daily Commute'
        ..icon = '🚗'
        ..createdAt = DateTime.now().subtract(const Duration(days: 20));

      final weekendTrip = Group()
        ..name = 'Weekend Trip'
        ..icon = '🏖️'
        ..createdAt = DateTime.now().subtract(const Duration(days: 15));

      await isar.collection<Group>().putAll([
        collegeFriends,
        dailyCommute,
        weekendTrip,
      ]);

      // Assign Members to Groups
      collegeFriends.members.addAll([
        currentMember,
        arun,
        priya,
        rahul,
        venkat,
      ]);
      dailyCommute.members.addAll([currentMember, arun, priya]);
      weekendTrip.members.addAll([currentMember, arun, rahul]);

      await collegeFriends.members.save();
      await dailyCommute.members.save();
      await weekendTrip.members.save();

      // 4. Create Expenses (Demo Scenarios)
      List<Expense> demoExpenses = [];

      final now = DateTime.now();

      // Scenario 1: UNEVEN EQUAL SPLIT (₹1,000 / 3)
      // Demo rounding: RK: 333.34, Arun: 333.33, Priya: 333.33
      final e1 = Expense()
        ..title = 'Birthday Pizza'
        ..totalAmount = 1000.0
        ..category = 'Food'
        ..categoryIcon = '🍕'
        ..date = now.subtract(const Duration(hours: 2))
        ..splitMode = 'uniform'
        ..contributions = [
          Contribution()
            ..memberId = currentMember.id
            ..memberName = currentMember.name
            ..amount = 1000.0,
        ]
        ..splits = SplitService.calculateUniform(1000.0, [
          currentMember,
          arun,
          priya,
        ]);
      e1.group.value = collegeFriends;
      demoExpenses.add(e1);

      // Scenario 2: EXACT / SPECIFIC VALUE SPLIT
      // Total 500. Venkat 200, Rahul 150, Priya 150.
      final e2 = Expense()
        ..title = 'Lab Notebooks'
        ..totalAmount = 500.0
        ..category = 'Printing'
        ..categoryIcon = '🖨️'
        ..date = now.subtract(const Duration(days: 1))
        ..splitMode = 'specific'
        ..contributions = [
          Contribution()
            ..memberId = priya.id
            ..memberName = priya.name
            ..amount = 500.0,
        ]
        ..splits = [
          Split()
            ..memberId = venkat.id
            ..memberName = venkat.name
            ..amount = 200.0,
          Split()
            ..memberId = rahul.id
            ..memberName = rahul.name
            ..amount = 150.0,
          Split()
            ..memberId = priya.id
            ..memberName = priya.name
            ..amount = 150.0,
        ];
      e2.group.value = collegeFriends;
      demoExpenses.add(e2);

      // Scenario 3: RATIO SPLIT (50%, 25%, 25%)
      // Total 2000. RK: 1000, Arun: 500, Rahul: 500.
      final e3 = Expense()
        ..title = 'GDG Tech Event'
        ..totalAmount = 2000.0
        ..category = 'Entertainment'
        ..categoryIcon = '🎟️'
        ..date = now.subtract(const Duration(days: 2))
        ..splitMode = 'ratio'
        ..contributions = [
          Contribution()
            ..memberId = arun.id
            ..memberName = arun.name
            ..amount = 2000.0,
        ]
        ..splits = SplitService.calculateFromRatios(
          2000.0,
          {currentMember.id: 50.0, arun.id: 25.0, rahul.id: 25.0},
          [currentMember, arun, rahul],
        );
      e3.group.value = collegeFriends;
      demoExpenses.add(e3);

      // Scenario 4: MULTIPLE PAYERS
      // Total 1000. Rahul pays 600, Venkat pays 400. Shared by all 5.
      final e4 = Expense()
        ..title = 'Canteen Lunch'
        ..totalAmount = 1000.0
        ..category = 'Food'
        ..categoryIcon = '🍱'
        ..date = now.subtract(const Duration(days: 3))
        ..splitMode = 'uniform'
        ..contributions = [
          Contribution()
            ..memberId = rahul.id
            ..memberName = rahul.name
            ..amount = 600.0,
          Contribution()
            ..memberId = venkat.id
            ..memberName = venkat.name
            ..amount = 400.0,
        ]
        ..splits = SplitService.calculateUniform(1000.0, [
          currentMember,
          arun,
          priya,
          rahul,
          venkat,
        ]);
      e4.group.value = collegeFriends;
      demoExpenses.add(e4);

      // Scenario 5 & 6: CIRCULAR DEBT & ZERO BALANCE
      // A(Arun) -> B(Priya) ₹100
      // B(Priya) -> C(RK) ₹100
      // C(RK) -> A(Arun) ₹100
      // Rahul has 0 balance in these 3.

      final e5 = Expense()
        ..title = 'Printout (Arun for Priya)'
        ..totalAmount = 100.0
        ..category = 'Printing'
        ..categoryIcon = '📄'
        ..date = now.subtract(const Duration(hours: 5))
        ..splitMode = 'specific'
        ..contributions = [
          Contribution()
            ..memberId = arun.id
            ..memberName = arun.name
            ..amount = 100.0,
        ]
        ..splits = [
          Split()
            ..memberId = priya.id
            ..memberName = priya.name
            ..amount = 100.0,
        ];
      e5.group.value = collegeFriends;
      demoExpenses.add(e5);

      final e6 = Expense()
        ..title = 'Snacks (Priya for ${currentMember.name})'
        ..totalAmount = 100.0
        ..category = 'Food'
        ..categoryIcon = '🍟'
        ..date = now.subtract(const Duration(days: 1, hours: 2))
        ..splitMode = 'specific'
        ..contributions = [
          Contribution()
            ..memberId = priya.id
            ..memberName = priya.name
            ..amount = 100.0,
        ]
        ..splits = [
          Split()
            ..memberId = currentMember.id
            ..memberName = currentMember.name
            ..amount = 100.0,
        ];
      e6.group.value = collegeFriends;
      demoExpenses.add(e6);

      final e7 = Expense()
        ..title = 'Bus Fare (${currentMember.name} for Arun)'
        ..totalAmount = 100.0
        ..category = 'Transport'
        ..categoryIcon = '🚌'
        ..date = now.subtract(const Duration(days: 2, hours: 1))
        ..splitMode = 'specific'
        ..contributions = [
          Contribution()
            ..memberId = currentMember.id
            ..memberName = currentMember.name
            ..amount = 100.0,
        ]
        ..splits = [
          Split()
            ..memberId = arun.id
            ..memberName = arun.name
            ..amount = 100.0,
        ];
      e7.group.value = collegeFriends;
      demoExpenses.add(e7);

      // Scenario: Analytics Data for other groups
      final e8 = Expense()
        ..title = 'Auto to College'
        ..totalAmount = 150.0
        ..category = 'Auto'
        ..categoryIcon = '🛺'
        ..date = now.subtract(const Duration(days: 4))
        ..splitMode = 'uniform'
        ..contributions = [
          Contribution()
            ..memberId = currentMember.id
            ..memberName = currentMember.name
            ..amount = 150.0,
        ]
        ..splits = SplitService.calculateUniform(150.0, [
          currentMember,
          arun,
          priya,
        ]);
      e8.group.value = dailyCommute;
      demoExpenses.add(e8);

      final e9 = Expense()
        ..title = 'Resort Stay'
        ..totalAmount = 4500.0
        ..category = 'Travel'
        ..categoryIcon = '🏨'
        ..date = now.subtract(const Duration(days: 10))
        ..splitMode = 'uniform'
        ..contributions = [
          Contribution()
            ..memberId = currentMember.id
            ..memberName = currentMember.name
            ..amount = 4500.0,
        ]
        ..splits = SplitService.calculateUniform(4500.0, [
          currentMember,
          arun,
          rahul,
        ]);
      e9.group.value = weekendTrip;
      demoExpenses.add(e9);

      final e10 = Expense()
        ..title = 'Group T-Shirts'
        ..totalAmount = 1200.0
        ..category = 'Shopping'
        ..categoryIcon = '👕'
        ..date = now.subtract(const Duration(days: 12))
        ..splitMode = 'uniform'
        ..contributions = [
          Contribution()
            ..memberId = rahul.id
            ..memberName = rahul.name
            ..amount = 1200.0,
        ]
        ..splits = SplitService.calculateUniform(1200.0, [
          currentMember,
          arun,
          rahul,
        ]);
      e10.group.value = weekendTrip;
      demoExpenses.add(e10);

      // Save all demo expenses and their links
      await isar.collection<Expense>().putAll(demoExpenses);
      for (var e in demoExpenses) {
        await e.group.save();
      }
    });
  }

  static Future<Member> _getOrCreateMember(
    Isar isar,
    String name,
    String initials,
    int color,
  ) async {
    Member? m = await isar
        .collection<Member>()
        .filter()
        .nameEqualTo(name)
        .findFirst();
    if (m == null) {
      m = Member(
        name: name,
        initials: initials,
        email: '${name.toLowerCase()}@univ.edu',
        colorValue: color,
      );
      await isar.collection<Member>().put(m);
    }
    return m;
  }
}
