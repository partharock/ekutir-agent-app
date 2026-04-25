void main() {
  List<int> myList = [];
  try {
    var result = myList.firstWhere((x) => x > 0, orElse: () => myList.last);
  } catch(e) {
    print(e);
  }
}
