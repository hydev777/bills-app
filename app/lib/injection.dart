import 'package:app/core/network/api_client.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource_impl.dart';
import 'package:app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/usecases/get_session_usecase.dart';
import 'package:app/features/auth/domain/usecases/login_usecase.dart';
import 'package:app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/products/data/datasources/products_remote_datasource.dart';
import 'package:app/features/products/data/datasources/products_remote_datasource_impl.dart';
import 'package:app/features/products/data/repositories/products_repository_impl.dart';
import 'package:app/features/products/domain/repositories/products_repository.dart';
import 'package:app/features/products/domain/usecases/create_item_usecase.dart';
import 'package:app/features/products/domain/usecases/get_categories_usecase.dart';
import 'package:app/features/products/domain/usecases/get_itbis_rates_usecase.dart';
import 'package:app/features/products/domain/usecases/get_items_usecase.dart';
import 'package:app/features/products/domain/usecases/update_item_usecase.dart';
import 'package:app/features/products/presentation/bloc/products_bloc.dart';
import 'package:app/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:app/features/clients/data/datasources/clients_remote_datasource_impl.dart';
import 'package:app/features/clients/data/repositories/clients_repository_impl.dart';
import 'package:app/features/clients/domain/repositories/clients_repository.dart';
import 'package:app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:app/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:app/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:app/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:app/features/bills/data/datasources/bills_remote_datasource.dart';
import 'package:app/features/bills/data/datasources/bills_remote_datasource_impl.dart';
import 'package:app/features/bills/data/repositories/bills_repository_impl.dart';
import 'package:app/features/bills/domain/repositories/bills_repository.dart';
import 'package:app/features/bills/domain/usecases/get_bills_usecase.dart';
import 'package:app/features/bills/domain/usecases/get_bill_by_id_usecase.dart';
import 'package:app/features/bills/domain/usecases/get_bill_by_public_id_usecase.dart';
import 'package:app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

final GetIt sl = GetIt.instance;

Future<void> initInjection() async {
  // Core
  sl.registerLazySingleton<Dio>(() => createApiClient());

  // Auth - Data
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
    ),
  );

  // Auth - Domain (use cases)
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetSessionUseCase>(
    () => GetSessionUseCase(sl<AuthRepository>()),
  );

  // Auth - Presentation (BLoC as singleton for router redirect)
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getSessionUseCase: sl<GetSessionUseCase>(),
    ),
  );

  // Products - Data
  sl.registerLazySingleton<ProductsRemoteDataSource>(
    () => ProductsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ProductsRepository>(
    () => ProductsRepositoryImpl(sl<ProductsRemoteDataSource>()),
  );

  // Products - Domain (use cases)
  sl.registerLazySingleton<GetItemsUseCase>(
    () => GetItemsUseCase(sl<ProductsRepository>()),
  );
  sl.registerLazySingleton<GetCategoriesUseCase>(
    () => GetCategoriesUseCase(sl<ProductsRepository>()),
  );
  sl.registerLazySingleton<GetItbisRatesUseCase>(
    () => GetItbisRatesUseCase(sl<ProductsRepository>()),
  );
  sl.registerLazySingleton<CreateItemUseCase>(
    () => CreateItemUseCase(sl<ProductsRepository>()),
  );
  sl.registerLazySingleton<UpdateItemUseCase>(
    () => UpdateItemUseCase(sl<ProductsRepository>()),
  );

  // Products - Presentation
  sl.registerLazySingleton<ProductsBloc>(
    () => ProductsBloc(
      getItemsUseCase: sl<GetItemsUseCase>(),
      getCategoriesUseCase: sl<GetCategoriesUseCase>(),
      getItbisRatesUseCase: sl<GetItbisRatesUseCase>(),
      createItemUseCase: sl<CreateItemUseCase>(),
      updateItemUseCase: sl<UpdateItemUseCase>(),
    ),
  );

  // Clients - Data
  sl.registerLazySingleton<ClientsRemoteDataSource>(
    () => ClientsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ClientsRepository>(
    () => ClientsRepositoryImpl(sl<ClientsRemoteDataSource>()),
  );

  // Clients - Domain (use cases)
  sl.registerLazySingleton<GetClientsUseCase>(
    () => GetClientsUseCase(sl<ClientsRepository>()),
  );
  sl.registerLazySingleton<CreateClientUseCase>(
    () => CreateClientUseCase(sl<ClientsRepository>()),
  );
  sl.registerLazySingleton<UpdateClientUseCase>(
    () => UpdateClientUseCase(sl<ClientsRepository>()),
  );

  // Clients - Presentation
  sl.registerFactory<ClientsBloc>(
    () => ClientsBloc(
      getClientsUseCase: sl<GetClientsUseCase>(),
      createClientUseCase: sl<CreateClientUseCase>(),
      updateClientUseCase: sl<UpdateClientUseCase>(),
    ),
  );

  // Bills - Data
  sl.registerLazySingleton<BillsRemoteDataSource>(
    () => BillsRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<BillsRepository>(
    () => BillsRepositoryImpl(sl<BillsRemoteDataSource>()),
  );

  // Bills - Domain (use cases)
  sl.registerLazySingleton<GetBillsUseCase>(
    () => GetBillsUseCase(sl<BillsRepository>()),
  );
  sl.registerLazySingleton<GetBillByIdUseCase>(
    () => GetBillByIdUseCase(sl<BillsRepository>()),
  );
  sl.registerLazySingleton<GetBillByPublicIdUseCase>(
    () => GetBillByPublicIdUseCase(sl<BillsRepository>()),
  );

  // Bills - Presentation
  sl.registerFactory<BillsBloc>(
    () => BillsBloc(
      getBillsUseCase: sl<GetBillsUseCase>(),
      getBillByIdUseCase: sl<GetBillByIdUseCase>(),
      getBillByPublicIdUseCase: sl<GetBillByPublicIdUseCase>(),
    ),
  );
}
