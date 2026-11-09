abstract interface class StudyStorage {
  Future<String?> read();
  Future<void> write(String contents);
}
