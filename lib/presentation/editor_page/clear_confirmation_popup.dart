part of 'editor_page.dart';
///
///
/// Всплывающее окно подтверждения при очистке плана
class ClearConfirmationPopup extends StatelessWidget {
  const ClearConfirmationPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Очистить план?'),
      content: Text(
        'После удаления все созданные элементы будут удалены, вы уверены что хотите очистить план?',
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontSize: 20, fontWeight: FontWeight.w300),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            false,
          ),
          child: Text(
            'Отмена',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            true,
          ),
          child: Text(
            'Очистить',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 20, fontWeight: FontWeight.w500,color:  Colors.red),
          ),
        ),
      ],
    );
  }
}
