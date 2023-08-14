import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:women_safety_app/components/PrimaryButton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewPage extends StatefulWidget {
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  TextEditingController locationC = TextEditingController();
  TextEditingController viewsC = TextEditingController();
  bool isSaving = false;
  String selectedLocation = '';
  late Stream<QuerySnapshot> reviewsStream;

  @override
  void initState() {
    super.initState();
    reviewsStream =
        FirebaseFirestore.instance.collection('reviews').snapshots();
  }

  showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Review your place"),
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: locationC,
                    onChanged: (value) {
                      setState(() {
                        selectedLocation = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter location',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                    ),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: viewsC,
                    decoration: InputDecoration(
                      hintText: 'Enter Comment',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                    ),
                    maxLines: 3,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            PrimaryButton(
              title: "SAVE",
              onPressed: () {
                saveReview();
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  saveReview() async {
    setState(() {
      isSaving = true;
    });
    await FirebaseFirestore.instance.collection('reviews').add({
      'location': locationC.text,
      'views': viewsC.text,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((value) {
      setState(() {
        isSaving = false;
        Fluttertoast.showToast(msg: 'Review uploaded successfully');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Center(
          child: Text(
            'Reviews',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: isSaving
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        selectedLocation = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by location',
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: reviewsStream,
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      List<DocumentSnapshot> sortedReviews =
                          snapshot.data!.docs;

                      List<DocumentSnapshot> matchingReviews = sortedReviews
                          .where((review) => review['location']
                              .toLowerCase()
                              .contains(selectedLocation.toLowerCase()))
                          .toList();

                      if (matchingReviews.isEmpty) {
                        return Center(
                            child: Text('No reviews in this location.'));
                      }

                      return ListView.builder(
                        itemCount: matchingReviews.length,
                        itemBuilder: (BuildContext context, int index) {
                          final data = matchingReviews[index];
                          final location = data['location'];

                          return AnimatedOpacity(
                            duration: Duration(milliseconds: 500),
                            opacity: 1.0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  title: Text(
                                    location,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    data['views'],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlueAccent,
        onPressed: () {
          showAlert(context);
        },
        child: Icon(Icons.add),
        tooltip: 'Add Review',
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Review Page Example',
    home: ReviewPage(),
  ));
}
