/// Minimal demo-time localization helper.
/// Pass [repository.isEnglish] (or a local [en] variable) to get the right string.
class L {
  const L._();

  static String t(bool isEnglish, String bangla, String english) =>
      isEnglish ? english : bangla;
}
