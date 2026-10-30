import 'package:flutter_test/flutter_test.dart';
import 'package:studylock/data/models/attendance_model.dart';
import 'package:studylock/data/models/models.dart';

void main() {
  group('QuizQuestion', () {
    test('fromJson applies safe defaults for missing fields', () {
      final q = QuizQuestion.fromJson({'id': 'q1'});
      expect(q.id, 'q1');
      expect(q.correctAnswer, 'A');
      expect(q.marks, 1);
      expect(q.questionText, isEmpty);
    });

    test('toJson/fromJson round-trip keeps data', () {
      const original = QuizQuestion(
        id: 'q7',
        questionText: 'What is 2 + 2?',
        optionA: '3',
        optionB: '4',
        optionC: '5',
        optionD: '22',
        correctAnswer: 'B',
        marks: 2,
      );
      final copy = QuizQuestion.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.correctAnswer, 'B');
      expect(copy.marks, 2);
      expect(copy.optionText('B'), '4');
      expect(copy.optionText('Z'), isEmpty);
    });
  });

  group('AttendanceStatus', () {
    test('parses known values', () {
      expect(AttendanceStatusX.from('present'), AttendanceStatus.present);
      expect(AttendanceStatusX.from('late'), AttendanceStatus.late);
    });

    test('unknown value falls back to absent', () {
      expect(AttendanceStatusX.from('???'), AttendanceStatus.absent);
    });

    test('value matches the database CHECK constraint names', () {
      expect(
        AttendanceStatus.values.map((s) => s.value).toSet(),
        {'present', 'absent', 'late', 'excused'},
      );
    });
  });
}
