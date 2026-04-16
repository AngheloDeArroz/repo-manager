import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:monday/services/github_api_service.dart';

GitHubApiService _service(http.Client client) {
  return GitHubApiService(getGitHubToken: () async => 'token', client: client);
}

void main() {
  test('createBranch returns auth failure when the token is missing', () async {
    final service = GitHubApiService(
      getGitHubToken: () async => null,
      client: MockClient((request) async {
        fail('No network request should be made without a token.');
      }),
    );

    final result = await service.createBranch(
      'octo',
      'demo',
      'feat/add-login',
      'base-sha',
    );

    expect(result.success, isFalse);
    expect(result.isAuthFailure, isTrue);
    expect(result.statusCode, 401);
  });

  test('createBranch returns parsed conflict details', () async {
    final service = _service(
      MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/repos/octo/demo/git/refs');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['ref'], 'refs/heads/feat/add-login');
        expect(body['sha'], 'base-sha');

        return http.Response(
          jsonEncode({'message': 'Reference already exists'}),
          422,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.createBranch(
      'octo',
      'demo',
      'feat/add-login',
      'base-sha',
    );

    expect(result.success, isFalse);
    expect(result.isConflict, isTrue);
    expect(result.statusCode, 422);
    expect(result.message, 'Reference already exists');
  });

  test('getBranch encodes branch names with slashes', () async {
    final service = _service(
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          contains('/repos/octo/demo/branches/feat%2Fadd-login'),
        );

        return http.Response(
          jsonEncode({
            'name': 'feat/add-login',
            'commit': {'sha': 'abc123'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final branch = await service.getBranch('octo', 'demo', 'feat/add-login');

    expect(branch?.name, 'feat/add-login');
    expect(branch?.sha, 'abc123');
  });

  test(
    'pushChanges encodes the ref path and surfaces GitHub failures',
    () async {
      final service = _service(
        MockClient((request) async {
          if (request.method == 'GET') {
            expect(request.url.path, '/repos/octo/demo/git/commits/base-sha');
            return http.Response(
              jsonEncode({
                'tree': {'sha': 'tree-base'},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/git/blobs')) {
            return http.Response(
              jsonEncode({'sha': 'blob-1'}),
              201,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/git/trees')) {
            return http.Response(
              jsonEncode({'sha': 'tree-2'}),
              201,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/git/commits')) {
            return http.Response(
              jsonEncode({'sha': 'commit-2'}),
              201,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.method == 'PATCH') {
            expect(
              request.url.toString(),
              contains('/repos/octo/demo/git/refs/heads/feat%2Fadd-login'),
            );
            return http.Response(
              jsonEncode({'message': 'Branch protected'}),
              422,
              headers: {'content-type': 'application/json'},
            );
          }

          throw StateError(
            'Unexpected request: ${request.method} ${request.url}',
          );
        }),
      );

      final result = await service.pushChanges(
        'octo',
        'demo',
        branch: 'feat/add-login',
        commitMessage: 'feat: add login',
        files: const {'lib/main.dart': 'void main() {}'},
        baseSha: 'base-sha',
      );

      expect(result.success, isFalse);
      expect(result.isConflict, isTrue);
      expect(result.statusCode, 422);
      expect(result.message, 'Branch protected');
    },
  );
}
