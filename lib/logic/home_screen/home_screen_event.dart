part of 'home_screen_bloc.dart';

@immutable
abstract class HomeScreenEvent {}

class HomeScreenChangeSelectedPageEvent extends HomeScreenEvent{
  final int page;

  HomeScreenChangeSelectedPageEvent({required this.page});
}