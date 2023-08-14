import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:women_safety_app/db/db_services.dart';
import 'package:women_safety_app/model/contactsm.dart';
import 'package:women_safety_app/utils/constants.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  DatabaseHelper _databaseHelper = DatabaseHelper();

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    askPermissions();
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }

  String? findPhoneNumber(Contact contact, String searchTermFlattren) {
    for (var phone in contact.phones ?? []) {
      String phnFLattered = flattenPhoneNumber(phone.value ?? "");
      if (phnFLattered.contains(searchTermFlattren)) {
        return phone.value;
      }
    }
    return null;
  }

  filterContact() {
    List<Contact> _contacts = [];
    _contacts.addAll(contacts);
    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((element) {
        String searchTerm = searchController.text.toLowerCase();
        String searchTermFlattren = flattenPhoneNumber(searchTerm);
        String contactName = element.displayName?.toLowerCase() ?? "";
        bool nameMatch = contactName.contains(searchTerm);
        if (nameMatch == true) {
          return true;
        }
        if (searchTermFlattren.isEmpty) {
          return false;
        }
        return findPhoneNumber(element, searchTermFlattren) != null;
      });
    }
    setState(() {
      contactsFiltered = _contacts;
    });
  }

  Future<void> askPermissions() async {
    PermissionStatus permissionStatus = await getContactsPermissions();
    if (permissionStatus == PermissionStatus.granted) {
      getAllContacts();
      searchController.addListener(() {
        filterContact();
      });
    } else {
      handleInvalidPermissions(permissionStatus);
    }
  }

  void handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Permission Denied"),
            content: Text("Access to the contacts denied by the user."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Permission Denied"),
            content: Text("Contacts permission permanently denied."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<PermissionStatus> getContactsPermissions() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  getAllContacts() async {
    List<Contact> _contacts =
        await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      contacts = _contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;
    bool listItemExist = contactsFiltered.length > 0 || contacts.length > 0;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onChanged: (value) {
            filterContact();
          },
          decoration: InputDecoration(
            hintText: "Search contact",
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              searchController.clear();
              filterContact();
            },
            icon: Icon(Icons.clear),
          ),
        ],
      ),
      body: contacts.length == 0
          ? Center(child: CircularProgressIndicator())
          : listItemExist
              ? ListView.builder(
                  itemCount:
                      isSearching ? contactsFiltered.length : contacts.length,
                  itemBuilder: (BuildContext context, int index) {
                    Contact contact =
                        isSearching ? contactsFiltered[index] : contacts[index];
                    return ListTile(
                      title: Text(contact.displayName ?? ''),
                      leading: CircleAvatar(
                        child: Text(contact.initials()),
                      ),
                      onTap: () {
                        if (contact.phones!.length > 0) {
                          final String phoneNumber =
                              contact.phones!.first.value ?? '';
                          final String name = contact.displayName ?? '';
                          _addContact(TContact(phoneNumber, name));
                        } else {
                          Fluttertoast.showToast(
                            msg:
                                "Oops! Phone number of this contact does not exist.",
                          );
                        }
                      },
                    );
                  },
                )
              : Center(
                  child: Text("No contacts found."),
                ),
    );
  }

  void _addContact(TContact newContact) async {
    int result = await _databaseHelper.insertContact(newContact);
    if (result != 0) {
      Fluttertoast.showToast(msg: "Contact added successfully");
      Navigator.of(context).pop(true);
    } else {
      Fluttertoast.showToast(msg: "Failed to add contact");
    }
  }
}
