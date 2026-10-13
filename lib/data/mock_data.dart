import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';

/// Local mock data. Dates are relative to today so the demo always looks
/// fresh. Replaced by a REST API and a database in later milestones.
class MockData {
  static Budget budget() {
    final now = DateTime.now();
    return Budget(
      balanceAtDayStart: 80000,
      nextStipendDate: DateTime(now.year, now.month, now.day + 25),
    );
  }

  static List<Expense> expenses() {
    final now = DateTime.now();
    DateTime at(int daysAgo, int hour, int minute) =>
        DateTime(now.year, now.month, now.day - daysAgo, hour, minute);

    return [
      Expense(
        id: 'e1',
        title: 'Обед в столовой',
        amount: 1800,
        category: ExpenseCategory.food,
        date: at(0, 13, 20),
        place: 'Столовая КБТУ',
        description:
            'Комплексный обед: суп, плов и компот. '
            'Дешевле, чем в кафе рядом с корпусом.',
        imageUrl:
            'https://images.unsplash.com/photo-1547592180-85f173990554?w=800',
        tags: ['Обед', 'Универ', 'Наличные'],
      ),
      Expense(
        id: 'e2',
        title: 'Кофе с собой',
        amount: 1200,
        category: ExpenseCategory.cafe,
        date: at(1, 9, 5),
        place: 'Coffee Boom',
        description: 'Капучино перед первой парой.',
        imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800',
        tags: ['Кофе', 'Утро', 'Kaspi'],
      ),
      Expense(
        id: 'e3',
        title: 'Проездной',
        amount: 4000,
        category: ExpenseCategory.transport,
        date: at(1, 8, 30),
        place: 'Onay',
        description: 'Пополнение карты Onay на месяц поездок.',
        imageUrl:
            'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800',
        tags: ['Транспорт', 'Месяц'],
      ),
      Expense(
        id: 'e4',
        title: 'Продукты на неделю',
        amount: 6500,
        category: ExpenseCategory.groceries,
        date: at(2, 19, 40),
        place: 'Magnum',
        description: 'Крупы, овощи, молоко и яйца на всю неделю.',
        imageUrl:
            'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800',
        tags: ['Продукты', 'Неделя', 'Kaspi'],
      ),
      Expense(
        id: 'e5',
        title: 'Кино с друзьями',
        amount: 2500,
        category: ExpenseCategory.leisure,
        date: at(3, 20, 15),
        place: 'Kinopark',
        description: 'Вечерний сеанс по студенческой скидке.',
        imageUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800',
        tags: ['Досуг', 'Друзья'],
      ),
    ];
  }
}
