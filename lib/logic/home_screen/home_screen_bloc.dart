import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'home_screen_event.dart';
part 'home_screen_state.dart';

class HomeScreenBloc extends Bloc<HomeScreenEvent, HomeScreenState> {
  int selectedPage = 1;
  HomeScreenBloc() : super(HomeScreenInitialState()) {
    on<HomeScreenEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<HomeScreenChangeSelectedPageEvent>((event, emit) {
      selectedPage = event.page;
      emit(HomeScreenMainState(selectedPage: selectedPage));
    });
    emit(HomeScreenMainState(selectedPage: selectedPage));
  }
}
