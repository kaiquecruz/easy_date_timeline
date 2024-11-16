import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:easy_date_timeline/src/easy_date_time_line_picker/utils/utils.exports.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'month_widget.dart';

const int _monthsCount = 12;
const int _monthPickerColumnCount = 3;
const double _monthPickerPadding = 16.0;
const double _monthPickerRowSpacing = 8.0;

/// A widget that displays a grid of months for selection.
///
/// The [MonthsGrid] widget is used to display a grid of months within a given
/// date range. It allows users to select a month, and it handles various states
/// such as the current month, selected month, and disabled months.
///
/// The widget requires several parameters:
///
/// * [currentPageIndex]: The index of the current page in the date picker.
/// * [firstDate]: The earliest date that can be selected.
/// * [lastDate]: The latest date that can be selected.
/// * [focusedDate]: The currently focused date.
/// * [currentDate]: The current date.
/// * [onChanged]: A callback that is called when a month is selected.
/// * [locale]: The locale to use for formatting dates.
/// * [disableStrategy]: A strategy for determining whether a date should be disabled.
///
/// The widget uses a [GridView.builder] to create the grid of months. Each month
/// is represented by a [MonthWidget], which handles the display and interaction
/// for a single month.
///
/// The [_handleMonthTap] method is used to handle taps on a month. It ensures
/// that the selected date is within the valid range and calls the [onChanged]
/// callback with the selected date.

class MonthsGrid extends StatelessWidget {
  MonthsGrid({
    super.key,
    required this.currentPageIndex,
    required this.firstDate,
    required this.lastDate,
    required this.focusedDate,
    required this.currentDate,
    required this.onChanged,
    required this.locale,
    required this.disableStrategy,
  }) : assert(!firstDate.isAfter(lastDate));

  final int currentPageIndex;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? focusedDate;
  final DateTime currentDate;
  final ValueChanged<DateTime> onChanged;
  final String? locale;
  final DisableStrategy disableStrategy;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: _monthPickerGridDelegate,
      itemBuilder: _buildMonthItem,
      itemCount: _monthsCount,
      padding: const EdgeInsets.symmetric(horizontal: _monthPickerPadding),
    );
  }

  Widget _buildMonthItem(BuildContext context, int index) {
    final date = _getDateForIndex(index);
    return MonthWidget(
      date: date,
      isDisabled: _isMonthDisabled(date),
      isSelected: _isMonthSelected(date),
      isCurrentMonth: _isCurrentMonth(date),
      onMonthSelected: _handleMonthTap,
      locale: locale,
    );
  }

  DateTime _getDateForIndex(int index) {
    final year = firstDate.year + currentPageIndex;
    return DateTime(year, index + 1);
  }

  bool _isMonthSelected(DateTime date) {
    return focusedDate != null &&
        date.month == focusedDate!.month &&
        date.year == focusedDate!.year;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.year == currentDate.year && date.month == currentDate.month;
  }

  void _handleMonthTap(DateTime date) {
    final selectedDate = _calculateSelectedDate(date);
    onChanged(_ensureDateInRange(selectedDate));
  }

  DateTime _calculateSelectedDate(DateTime date) {
    if (_isFirstMonth(date)) {
      return DateTime(date.year, date.month, firstDate.day);
    }

    if (_isLastMonth(date)) {
      return DateTime(date.year, date.month, lastDate.day);
    }

    if (disableStrategy.isDisabled(date)) {
      final firstNonDisabledDay = _getFirstNonDisabledDay(date);
      return DateTime(date.year, date.month, firstNonDisabledDay);
    }

    return DateTime(date.year, date.month, 1);
  }

  // Checks if the given [date] is the first month in the range.
  //
  // This method compares the year and month of the provided [date] with
  // the year and month of the [firstDate] to determine if it is the first month.
  //
  // Returns `true` if the [date] is the first month, otherwise `false`.
  //
  // - Parameter [date]: The date to be checked.
  // - Returns: A boolean indicating whether the [date] is the first month.
  bool _isFirstMonth(DateTime date) {
    return date.year == firstDate.year && date.month == firstDate.month;
  }

  // Checks if the given date is the last month in the range.
  //
  // This method compares the year and month of the provided [date] with the
  // year and month of the [lastDate] to determine if they are the same.
  //
  // Returns `true` if the [date] is in the same year and month as the [lastDate],
  // otherwise returns `false`.
  //
  // - Parameter date: The date to be checked.
  // - Returns: A boolean indicating whether the given date is the last month.
  bool _isLastMonth(DateTime date) {
    return date.year == lastDate.year && date.month == lastDate.month;
  }

  // Ensures that the given [date] is within the range defined by [firstDate] and [lastDate].
  //
  // If [date] is before [firstDate], returns [firstDate].
  // If [date] is after [lastDate], returns [lastDate].
  // Otherwise, returns the original [date].
  //
  // - Parameter date: The date to be checked and adjusted if necessary.
  // - Returns: A [DateTime] object that is within the specified range.
  DateTime _ensureDateInRange(DateTime date) {
    if (date.isBefore(firstDate)) return firstDate;
    if (date.isAfter(lastDate)) return lastDate;
    return date;
  }

  // Returns the first non-disabled day of the given month.
  //
  // This method generates all the days of the month for the given [date]
  // and returns the day of the first date that is not disabled according to
  // the [disableStrategy]. If all days are disabled, it returns the first day
  // of the month.
  //
  // - Parameter [date]: The date for which to find the first non-disabled day.
  // - Returns: The day of the first non-disabled date in the month.
  int _getFirstNonDisabledDay(DateTime date) {
    return generateMonthDays(date)
        .firstWhere(
          (date) => !disableStrategy.isDisabled(date),
          orElse: () => date.copyWith(day: 1),
        )
        .day;
  }

  // Checks if a given month has any dates that fall within the allowed date range.
  //
  // For example, if firstDate is March 15, 2024 and lastDate is May 20, 2024:
  // - March 2024 is in range (even though days 1-14 are before firstDate)
  // - April 2024 is fully in range
  // - May 2024 is in range (even though days 21-31 are after lastDate)
  // - February 2024 is out of range (entirely before firstDate)
  // - June 2024 is out of range (entirely after lastDate)
  //
  // param date Any date within the month to check
  // returns true if any part of the month falls within firstDate and lastDate
  bool _isDateInRange(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0);
    return !(endOfMonth.isBefore(firstDate) || startOfMonth.isAfter(lastDate));
  }

  // Checks if the given month is disabled.
  //
  // This method first checks if the provided [date] is within the allowed range.
  // If the date is out of range, it returns `true`, indicating the month is disabled.
  // If the date is within range, it generates all the days of the month and checks
  // if every day in the month is disabled according to the [disableStrategy].
  //
  // Returns `true` if the month is disabled, otherwise `false`.
  //
  // - Parameter date: The [DateTime] object representing the month to check.
  // - Returns: A boolean value indicating whether the month is disabled.
  bool _isMonthDisabled(DateTime date) {
    if (!_isDateInRange(date)) return true;
    return generateMonthDays(date).every(disableStrategy.isDisabled);
  }
}

class _MonthPickerGridDelegate extends SliverGridDelegate {
  const _MonthPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double tileWidth = (constraints.crossAxisExtent -
            (_monthPickerColumnCount - 1) * _monthPickerRowSpacing) /
        _monthPickerColumnCount;
    final double tileHeight = constraints.viewportMainAxisExtent / 4;
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth,
      childMainAxisExtent: tileHeight,
      crossAxisCount: _monthPickerColumnCount,
      crossAxisStride: tileWidth + _monthPickerRowSpacing,
      mainAxisStride: tileHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_MonthPickerGridDelegate oldDelegate) => false;
}

const _MonthPickerGridDelegate _monthPickerGridDelegate =
    _MonthPickerGridDelegate();

// class MonthsGrid extends StatelessWidget {
//   MonthsGrid({
//     super.key,
//     required this.currentPageIndex,
//     required this.firstDate,
//     required this.lastDate,
//     required this.focusedDate,
//     required this.currentDate,
//     required this.onChanged,
//     required this.locale,
//     required this.disableStrategy,
//   }) : assert(!firstDate.isAfter(lastDate));

//   /// The index of the current page in the date picker.
//   final int currentPageIndex;

//   /// The earliest date that can be selected.
//   final DateTime firstDate;

//   /// The latest date that can be selected.
//   final DateTime lastDate;

//   /// The currently focused date.
//   final DateTime? focusedDate;

//   /// A callback that is called when a month is selected.
//   final DateTime currentDate;

//   /// The locale to use for formatting dates.
//   final ValueChanged<DateTime> onChanged;

//   /// The locale to use for formatting dates.
//   final String? locale;

//   /// A strategy for determining whether a date should be disabled.
//   final DisableStrategy disableStrategy;

//   @override
//   Widget build(BuildContext context) {
//     return GridView.builder(
//       physics: const NeverScrollableScrollPhysics(), // Disable scrolling
//       gridDelegate: _monthPickerGridDelegate,
//       itemBuilder: (context, index) {
//         final year = firstDate.year + currentPageIndex;
//         final date = DateTime(year, index + 1);
//         final bool isSelected =
//             date.month == focusedDate?.month && date.year == focusedDate?.year;
//         final bool isCurrentMonth =
//             date.year == currentDate.year && date.month == currentDate.month;
//         final bool isDisabled = _isMonthDisabled(date);
//         return MonthWidget(
//           date: date,
//           isDisabled: isDisabled,
//           isSelected: isSelected,
//           isCurrentMonth: isCurrentMonth,
//           onMonthSelected: _handleMonthTap,
//           locale: locale,
//         );
//       },
//       itemCount: _monthsCount,
//       padding: const EdgeInsets.symmetric(horizontal: _monthPickerPadding),
//     );
//   }

//   void _handleMonthTap(DateTime date) {
//     DateTime selectedDate;

//     if (date.year == firstDate.year && date.month == firstDate.month) {
//       // If it's the first month, use firstDate's day
//       selectedDate = DateTime(date.year, date.month, firstDate.day);
//     } else if (date.year == lastDate.year && date.month == lastDate.month) {
//       // If it's the last month, use lastDate's day
//       selectedDate = DateTime(date.year, date.month, lastDate.day);
//     } else {
//       // For any other month, use the first day of the month
//       if (disableStrategy.isDisabled(date)) {
//         final firstNonDisabledDay = _getFirstNonDisabledDay(date);
//         selectedDate = DateTime(date.year, date.month, firstNonDisabledDay);
//       } else {
//         selectedDate = DateTime(date.year, date.month, 1);
//       }
//     }

//     // Ensure the selected date is within the valid range
//     if (selectedDate.isBefore(firstDate)) {
//       selectedDate = firstDate;
//     } else if (selectedDate.isAfter(lastDate)) {
//       selectedDate = lastDate;
//     }
//     onChanged(selectedDate);
//   }

//   int _getFirstNonDisabledDay(DateTime date) {
//     final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
//     for (var day = 1; day <= daysInMonth; day++) {
//       if (!disableStrategy.isDisabled(DateTime(date.year, date.month, day))) {
//         return day;
//       }
//     }
//     return 1; // Default to the 1st day if all days are disabled
//   }

//   /// Checks if a given month has any dates that fall within the allowed date range.
//   ///
//   /// For example, if firstDate is March 15, 2024 and lastDate is May 20, 2024:
//   /// - March 2024 is in range (even though days 1-14 are before firstDate)
//   /// - April 2024 is fully in range
//   /// - May 2024 is in range (even though days 21-31 are after lastDate)
//   /// - February 2024 is out of range (entirely before firstDate)
//   /// - June 2024 is out of range (entirely after lastDate)
//   ///
//   /// param date Any date within the month to check
//   /// returns true if any part of the month falls within firstDate and lastDate
//   bool _isDateInRange(DateTime date) {
//     final startOfMonth = DateTime(date.year, date.month, 1);
//     final endOfMonth = DateTime(date.year, date.month + 1, 0);
//     return !(endOfMonth.isBefore(firstDate) || startOfMonth.isAfter(lastDate));
//   }

//   bool _isMonthDisabled(DateTime date) {
//     if (!_isDateInRange(date)) return true;
//     return generateMonthDays(date).every(disableStrategy.isDisabled);
//   }
// }

// bool _isMonthDisabled(DateTime date) {
//   final isBeforeFirstDate =
//       DateTime(date.year, date.month + 1, 1).isBefore(firstDate);
//   final isAfterLastDate =
//       DateTime(date.year, date.month, 1).isAfter(lastDate);
//   if (isBeforeFirstDate || isAfterLastDate) return true;
//   return generateMonthDays(date).every(disableStrategy.isDisabled);
// }

/// A custom [SliverGridDelegate] that defines the layout for a month picker grid.
///
/// This delegate arranges the grid tiles with a fixed number of columns and
/// calculates the tile width and height based on the available constraints.
///
/// The layout is defined by:
/// - A fixed number of columns specified by `_monthPickerColumnCount`.
/// - A fixed row spacing specified by `_monthPickerRowSpacing`.
/// - Tile width calculated based on the cross axis extent and row spacing.
/// - Tile height calculated as one-fourth of the viewport main axis extent.

// import 'package:easy_date_timeline/easy_date_timeline.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';

// import 'month_widget.dart';

// const int _monthsCount = 12;
// const int _monthPickerColumnCount = 3;
// const double _monthPickerPadding = 16.0;
// const double _monthPickerRowSpacing = 8.0;

// /// A widget that displays a grid of months for selection.
// ///
// /// The [MonthsGrid] widget is used to display a grid of months within a given
// /// date range. It allows users to select a month, and it handles various states
// /// such as the current month, selected month, and disabled months.
// ///
// /// The widget requires several parameters:
// ///
// /// * [currentPageIndex]: The index of the current page in the date picker.
// /// * [firstDate]: The earliest date that can be selected.
// /// * [lastDate]: The latest date that can be selected.
// /// * [focusedDate]: The currently focused date.
// /// * [currentDate]: The current date.
// /// * [onChanged]: A callback that is called when a month is selected.
// /// * [locale]: The locale to use for formatting dates.
// /// * [disableStrategy]: A strategy for determining whether a date should be disabled.
// ///
// /// The widget uses a [GridView.builder] to create the grid of months. Each month
// /// is represented by a [MonthWidget], which handles the display and interaction
// /// for a single month.
// ///
// /// The [_handleMonthTap] method is used to handle taps on a month. It ensures
// /// that the selected date is within the valid range and calls the [onChanged]
// /// callback with the selected date.

// class MonthsGrid extends StatelessWidget {
//   MonthsGrid({
//     super.key,
//     required this.currentPageIndex,
//     required this.firstDate,
//     required this.lastDate,
//     required this.focusedDate,
//     required this.currentDate,
//     required this.onChanged,
//     required this.locale,
//     required this.disableStrategy,
//   }) : assert(!firstDate.isAfter(lastDate));

//   /// The index of the current page in the date picker.
//   final int currentPageIndex;

//   /// The earliest date that can be selected.
//   final DateTime firstDate;

//   /// The latest date that can be selected.
//   final DateTime lastDate;

//   /// The currently focused date.
//   final DateTime? focusedDate;

//   /// A callback that is called when a month is selected.
//   final DateTime currentDate;

//   /// The locale to use for formatting dates.
//   final ValueChanged<DateTime> onChanged;

//   /// The locale to use for formatting dates.
//   final String? locale;

//   /// A strategy for determining whether a date should be disabled.
//   final DisableStrategy disableStrategy;

//   @override
//   Widget build(BuildContext context) {
//     return GridView.builder(
//       physics: const NeverScrollableScrollPhysics(), // Disable scrolling
//       gridDelegate: _monthPickerGridDelegate,
//       itemBuilder: (context, index) {
//         final year = firstDate.year + currentPageIndex;
//         final date = DateTime(
//           year,
//           index + 1,
//         );
//         final bool isSelected =
//             date.month == focusedDate?.month && date.year == focusedDate?.year;
//         final bool isCurrentMonth =
//             date.year == currentDate.year && date.month == currentDate.month;
//         final bool isMonthBeforeFirstDate =
//             DateTime(date.year, date.month + 1, 1).isBefore(firstDate);
//         final bool isMonthAfterLastDate =
//             DateTime(date.year, date.month, 1).isAfter(lastDate);
//         final bool isDisabled = _isMonthDisabled(
//           date: date,
//           isBeforeFirstDate: isMonthBeforeFirstDate,
//           isAfterLastDate: isMonthAfterLastDate,
//         );
//         return MonthWidget(
//           date: date,
//           isDisabled: isDisabled,
//           isSelected: isSelected,
//           isCurrentMonth: isCurrentMonth,
//           onMonthSelected: _handleMonthTap,
//           locale: locale,
//         );
//       },
//       itemCount: _monthsCount,
//       padding: const EdgeInsets.symmetric(horizontal: _monthPickerPadding),
//     );
//   }

//   void _handleMonthTap(DateTime date) {
//     DateTime selectedDate;

//     if (date.year == firstDate.year && date.month == firstDate.month) {
//       // If it's the first month, use firstDate's day
//       selectedDate = DateTime(date.year, date.month, firstDate.day);
//     } else if (date.year == lastDate.year && date.month == lastDate.month) {
//       // If it's the last month, use lastDate's day
//       selectedDate = DateTime(date.year, date.month, lastDate.day);
//     } else {
//       // For any other month, use the first day of the month
//       if (disableStrategy.isDisabled(date)) {
//         final int daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
//         int firstNonDisabledDay = 1;
//         for (int day = 1; day <= daysInMonth; day++) {
//           if (!disableStrategy
//               .isDisabled(DateTime(date.year, date.month, day))) {
//             firstNonDisabledDay = day;
//             break;
//           }
//         }
//         selectedDate = DateTime(date.year, date.month, firstNonDisabledDay);
//       } else {
//         selectedDate = DateTime(date.year, date.month, 1);
//       }
//     }

//     // Ensure the selected date is within the valid range
//     if (selectedDate.isBefore(firstDate)) {
//       selectedDate = firstDate;
//     } else if (selectedDate.isAfter(lastDate)) {
//       selectedDate = lastDate;
//     }
//     onChanged(selectedDate);
//   }

//   bool _isMonthDisabled({
//     required DateTime date,
//     required bool isBeforeFirstDate,
//     required bool isAfterLastDate,
//   }) {
//     if (isBeforeFirstDate || isAfterLastDate) {
//       return true;
//     } else {
//       // Check if all days in the month are disabled
//       final int daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
//       for (int day = 1; day <= daysInMonth; day++) {
//         if (!disableStrategy.isDisabled(DateTime(date.year, date.month, day))) {
//           return false;
//         }
//       }
//       return true;
//     }
//   }
// }

// /// A custom [SliverGridDelegate] that defines the layout for a month picker grid.
// ///
// /// This delegate arranges the grid tiles with a fixed number of columns and
// /// calculates the tile width and height based on the available constraints.
// ///
// /// The layout is defined by:
// /// - A fixed number of columns specified by `_monthPickerColumnCount`.
// /// - A fixed row spacing specified by `_monthPickerRowSpacing`.
// /// - Tile width calculated based on the cross axis extent and row spacing.
// /// - Tile height calculated as one-fourth of the viewport main axis extent.
// class _MonthPickerGridDelegate extends SliverGridDelegate {
//   const _MonthPickerGridDelegate();

//   @override
//   SliverGridLayout getLayout(SliverConstraints constraints) {
//     final double tileWidth = (constraints.crossAxisExtent -
//             (_monthPickerColumnCount - 1) * _monthPickerRowSpacing) /
//         _monthPickerColumnCount;
//     final double tileHeight = constraints.viewportMainAxisExtent / 4;
//     return SliverGridRegularTileLayout(
//       childCrossAxisExtent: tileWidth,
//       childMainAxisExtent: tileHeight,
//       crossAxisCount: _monthPickerColumnCount,
//       crossAxisStride: tileWidth + _monthPickerRowSpacing,
//       mainAxisStride: tileHeight,
//       reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
//     );
//   }

//   @override
//   bool shouldRelayout(_MonthPickerGridDelegate oldDelegate) => false;
// }

// const _MonthPickerGridDelegate _monthPickerGridDelegate =
//     _MonthPickerGridDelegate();