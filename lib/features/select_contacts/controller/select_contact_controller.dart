import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/select_contacts/repository/select_contacts_repository.dart';

final getContactsProvider = FutureProvider((ref) {
  final selectContactRepository = ref.watch(selectContactsRepositoryProvider);
  return selectContactRepository.getContacts();
});

final selectContactControllerProvider = Provider((ref) {
  final selectContactRepository = ref.watch(selectContactsRepositoryProvider);
  return SelectContactController(ref,selectContactRepository);
});

class SelectContactController {
  final ProviderRef ref;
  final SelectContactRepository selectContactRepository;

  SelectContactController(this.ref, this.selectContactRepository);

  void selectContact(Contact selectedContact, BuildContext context) {
    selectContactRepository.selectContacts(selectedContact, context);
  }
}
