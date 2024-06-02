import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
import 'package:gas_distribution_station_model/logic/home_screen/home_screen_bloc.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeScreenBloc>(
      create: (_) => HomeScreenBloc(),
      child: BlocBuilder<HomeScreenBloc, HomeScreenState>(
        builder: (context, state) {
          return Scaffold(
              body: Row(
            children: [
              BlocBuilder<HomeScreenBloc, HomeScreenState>(
                builder: (context, state) {
                  if (state is HomeScreenMainState) {
                    return SideMenu(
                      builder: (data) => SideMenuData(
                        header: const Text(''),
                        items: [
                          SideMenuItemDataTile(
                            isSelected: state.selectedPage == 1,
                            onTap: () {
                              context.read<HomeScreenBloc>().add(
                                  HomeScreenChangeSelectedPageEvent(page: 1));
                            },
                            title: 'Редактирование',
                            icon: const Icon(Icons.account_tree),
                          ),
                          // SideMenuItemDataTile(
                          //   isSelected: state.selectedPage == 2,
                          //   onTap: () {
                          //     context.read<HomeScreenBloc>().add(
                          //         HomeScreenChangeSelectedPageEvent(page: 2));
                          //   },
                          //   title: 'Вычисление',
                          //   icon: const Icon(Icons.calculate),
                          // ),
                        ],
                        footer: const Text(''),
                      ),
                    );
                  }
                  if (state is HomeScreenInitialState) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    throw Exception("unexpected state: $state");
                  }
                },
              ),
              BlocBuilder<HomeScreenBloc, HomeScreenState>(
                  builder: (context, state) {
                if (state is HomeScreenMainState) {
                  switch (state.selectedPage) {
                    case 1:
                      return const Expanded(child: EditorPageWidget());
                    // case 2:
                    //   return const Expanded(child: ViewerPageWidget());
                  }
                  throw Exception("bad page value: ${state.selectedPage}");
                } else if (state is HomeScreenInitialState) {
                  return const Center(child: CircularProgressIndicator());
                }
                throw Exception("unexpected state: $state");
              }),
            ],
          ));
        },
      ),
    );
  }
}
