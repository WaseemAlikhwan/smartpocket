/// One row of a category breakdown for a given period.
///
/// [percent] is the share of the period's total expense in `[0, 100]`.
class CategoryAnalysisItem {
  const CategoryAnalysisItem({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.amountMinor,
    required this.percent,
  });

  final String categoryId;
  final String name;
  final String iconKey;
  final int colorValue;
  final int amountMinor;
  final double percent;
}
