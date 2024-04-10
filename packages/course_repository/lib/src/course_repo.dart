import 'models/models.dart';


abstract class CourseRepository {
  Stream<Course?> get course;

  Future<Course> createCourse(Course course, String userId);

  Future<void> setCourseData(Course course);

  Future<void> deleteCourse(String courseId);

  Future<void> updateCourse(Course course);

  Future<void> joinCourse(String courseId);

  Future<void> leaveCourse(String courseId);
}