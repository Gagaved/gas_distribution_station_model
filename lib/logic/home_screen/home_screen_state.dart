part of 'home_screen_bloc.dart';

@immutable
abstract class HomeScreenState {}

class HomeScreenInitialState extends HomeScreenState {}

class HomeScreenMainState extends HomeScreenState {
  final int selectedPage;

  HomeScreenMainState({required this.selectedPage});
}
